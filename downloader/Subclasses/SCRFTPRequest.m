//
//  SCRFTPRequest.m
//  SCRFtpClient
//
//  Created by Aleks Nesterow on 10/28/09.
//  aleks.nesterow@gmail.com
//
//  Download and Directory Listing support added by Nathaniel Symer on 3/24/13
//  nate@natesymer.com
//	
//	Inspired by http://allseeing-i.com/ASIHTTPRequest/
//	Was using code samples from http://developer.apple.com/iphone/library/samplecode/SimpleFTPSample/index.html
//	and http://developer.apple.com/mac/library/samplecode/CFFTPSample/index.html
//  
//  Copyright © 2009, 7touch Group, Inc.
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//  * Redistributions of source code must retain the above copyright
//  notice, this list of conditions and the following disclaimer.
//  * Redistributions in binary form must reproduce the above copyright
//  notice, this list of conditions and the following disclaimer in the
//  documentation and/or other materials provided with the distribution.
//  * Neither the name of the 7touchGroup, Inc. nor the
//  names of its contributors may be used to endorse or promote products
//  derived from this software without specific prior written permission.
//  
//  THIS SOFTWARE IS PROVIDED BY 7touchGroup, Inc. "AS IS" AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL 7touchGroup, Inc. BE LIABLE FOR ANY
//  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//  

#import "SCRFTPRequest.h"

#import <sys/dirent.h>

NSString *const SCRFTPRequestErrorDomain = @"SCRFTPRequestErrorDomain";

static NSError *SCRFTPRequestTimedOutError;
static NSError *SCRFTPAuthenticationError;
static NSError *SCRFTPRequestCancelledError;
static NSError *SCRFTPUnableToCreateRequestError;

static NSOperationQueue *sharedRequestQueue = nil;

@interface SCRFTPRequest (/* Private */)

@property (nonatomic, retain) NSOutputStream *writeStream;
@property (nonatomic, retain) NSInputStream *readStream;
@property (nonatomic, retain) NSDate *timeOutDate;
@property (nonatomic, retain) NSRecursiveLock *cancelledLock;

- (void)applyCredentials;
- (void)cleanUp;
- (NSError *)constructErrorWithCode:(NSInteger)code message:(NSString *)message;
- (void)failWithError:(NSError *)error;
- (void)initializeComponentWithURL:(NSURL *)ftpURL operation:(SCRFTPRequestOperation)operation;
- (BOOL)isComplete;
- (void)requestFinished;
- (void)setStatus:(SCRFTPRequestStatus)status;
- (void)startUploadRequest;
- (void)handleUploadEvent:(NSStreamEvent)eventCode;
- (void)startCreateDirectoryRequest;
- (void)handleCreateDirectoryEvent:(NSStreamEvent)eventCode;
- (void)resetTimeout;

@end

@implementation NSString (SCRFTPRequest)

- (NSString *)scr_stringByFixingForURL {
    NSString *lastChar = [self substringFromIndex:self.length-1];
    if (![lastChar isEqualToString:@"/"]) {
        return [self stringByAppendingString:@"/"];
    }
    return self;
}

@end

@implementation SCRFTPRequest

@synthesize delegate = _delegate, didFinishSelector = _didFinishSelector, didFailSelector = _didFailSelector;
@synthesize willStartSelector = _willStartSelector, didChangeStatusSelector = _didChangeStatusSelector, bytesWrittenSelector = _bytesWrittenSelector;
@synthesize fileSize = _fileSize, bytesWritten = _bytesWritten, error = _error;
@synthesize operation = _operation;
@synthesize userInfo = _userInfo;
@synthesize username = _username, password = _password;
@synthesize ftpURL = _ftpURL, filePath = _filePath, directoryName = _directoryName;
@synthesize status = _status;

@synthesize timeOutSeconds = _timeOutSeconds;
@synthesize timeOutDate = _timeOutDate;
@synthesize cancelledLock = _cancelledLock;
@synthesize customUploadFileName, directoryContents;

/* Private */
@synthesize writeStream = _writeStream, readStream = _readStream;

- (void)setStatus:(SCRFTPRequestStatus)status {
	if (_status != status) {
		_status = status;
		if (self.didChangeStatusSelector && [self.delegate respondsToSelector:self.didChangeStatusSelector]) {
			[self.delegate performSelectorOnMainThread:self.didChangeStatusSelector withObject:self waitUntilDone:[NSThread isMainThread]];
		}
	}
}

#pragma mark init

+ (void)initialize {
	
	if (self == [SCRFTPRequest class]) {
		
		SCRFTPRequestTimedOutError = [[NSError errorWithDomain:SCRFTPRequestErrorDomain
														 code:SCRFTPRequestTimedOutErrorType
													 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
															   NSLocalizedString(@"The request timed out.", @""),
															   NSLocalizedDescriptionKey, nil]] retain];	
		SCRFTPAuthenticationError = [[NSError errorWithDomain:SCRFTPRequestErrorDomain
														code:SCRFTPAuthenticationErrorType
													userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
															  NSLocalizedString(@"Authentication needed.", @""),
															  NSLocalizedDescriptionKey, nil]] retain];
		SCRFTPRequestCancelledError = [[NSError errorWithDomain:SCRFTPRequestErrorDomain
														  code:SCRFTPRequestCancelledErrorType
													  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																NSLocalizedString(@"The request was cancelled.", @""),
																NSLocalizedDescriptionKey, nil]] retain];
		SCRFTPUnableToCreateRequestError = [[NSError errorWithDomain:SCRFTPRequestErrorDomain
															   code:SCRFTPUnableToCreateRequestErrorType
														   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																	 NSLocalizedString(@"Unable to create request (bad url?)", @""),
																	 NSLocalizedDescriptionKey,nil]] retain];
	}
	
	[super initialize];
}

- (id)init {
	if (self = [super init]) {
		[self initializeComponentWithURL:nil operation:SCRFTPRequestOperationDownload];
	}
	return self;
}

- (id)initWithURL:(NSURL *)ftpURL toDownloadFile:(NSString *)filePath {
	if (self = [super init]) {
		[self initializeComponentWithURL:ftpURL operation:SCRFTPRequestOperationDownload];
		self.filePath = filePath;
	}
	return self;
}

- (id)initWithURL:(NSURL *)ftpURL toUploadFile:(NSString *)filePath {
	if (self = [super init]) {
		[self initializeComponentWithURL:ftpURL operation:SCRFTPRequestOperationUpload];
		self.filePath = filePath;
	}
	return self;
}

- (id)initWithURL:(NSURL *)ftpURL toCreateDirectory:(NSString *)directoryName {
	if (self = [super init]) {
		[self initializeComponentWithURL:ftpURL operation:SCRFTPRequestOperationCreateDirectory];
		self.directoryName = directoryName;
	}
	return self;
}

- (id)initWithURLToListDirectory:(NSURL *)ftpURL {
	if (self = [super init]) {
		[self initializeComponentWithURL:ftpURL operation:SCRFTPRequestOperationListDirectory];
	}
	return self;
}

- (void)initializeComponentWithURL:(NSURL *)ftpURL operation:(SCRFTPRequestOperation)operation {
	self.ftpURL = ftpURL;
	self.operation = operation;
	self.timeOutSeconds = 10;
	self.cancelledLock = [[[NSRecursiveLock alloc]init]autorelease];
}

+ (id)requestWithURL:(NSURL *)ftpURL toDownloadFile:(NSString *)filePath {
	return [[[self alloc]initWithURL:ftpURL toDownloadFile:filePath]autorelease];
}

+ (id)requestWithURL:(NSURL *)ftpURL toUploadFile:(NSString *)filePath {
	return [[[self alloc]initWithURL:ftpURL toUploadFile:filePath]autorelease];
}

+ (id)requestWithURL:(NSURL *)ftpURL toCreateDirectory:(NSString *)directoryName {
	return [[[self alloc]initWithURL:ftpURL toCreateDirectory:directoryName]autorelease];
}

+ (id)requestWithURLToListDirectory:(NSURL *)ftpURL {
    return [[[self alloc]initWithURLToListDirectory:ftpURL]autorelease];
}


#pragma mark * Core transfer code

- (void)handleListEvent:(NSStreamEvent)eventCode {
    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            [self setStatus:SCRFTPRequestStatusOpenNetworkConnection];
        } break;
        case NSStreamEventHasBytesAvailable: {
            [self setStatus:SCRFTPRequestStatusReadingFromStream];
            
            uint8_t buffer[32768];
            
            NSInteger bytesRead = [self.readStream read:buffer maxLength:sizeof(buffer)];
            if (bytesRead == -1) {
                [self failWithError:[self constructErrorWithCode:SCRFTPConnectionFailureErrorType message:[NSString stringWithFormat:@"Cannot continue listing the remote directory: %@",self.ftpURL.absoluteString]]];
                return;
            } else if (bytesRead == 0) {
                [self requestFinished];
            } else {
                NSData *dataToParse = [NSData dataWithBytes:buffer length:(NSUInteger)bytesRead];
                [self parseListData:dataToParse];
            }
        } break;
        case NSStreamEventHasSpaceAvailable: {
            assert(NO);     // should never happen for the output stream
        } break;
        case NSStreamEventErrorOccurred: {
            CFStreamError err = CFReadStreamGetError((CFReadStreamRef)self.readStream);
            if (err.domain == kCFStreamErrorDomainFTP) {
                NSLog(@"here to bang");
                
                [self failWithError:[self constructErrorWithCode:SCRFTPConnectionFailureErrorType message:[NSString stringWithFormat:@"FTP error %d", (int)err.error]]];
            } else {
				[self failWithError:[self constructErrorWithCode:SCRFTPConnectionFailureErrorType message:@"Cannot open FTP connection."]];
            }
        } break;
        case NSStreamEventEndEncountered: {
            // ignore
        } break;
        default: {
            assert(NO);
        } break;
    }

}

- (void)startListDirectoriesRequest {
    
    if (!self.ftpURL) {
		[self failWithError:SCRFTPUnableToCreateRequestError];
		return;
	}
    
    self.directoryContents = [NSMutableArray array];
    
    CFReadStreamRef readStreamRef = CFReadStreamCreateWithFTPURL(kCFAllocatorDefault, (CFURLRef)self.ftpURL);
    
    if (!readStreamRef) {
        [self failWithError:[self constructErrorWithCode:SCRFTPUnableToCreateRequestErrorType message:[NSString stringWithFormat:@"Cannot open FTP connection to %@",self.ftpURL]]];
        return;
    }
    
    self.readStream = (NSInputStream *)readStreamRef;
    CFRelease(readStreamRef);
    
    [self applyCredentials];
    
    if (self.willStartSelector && [self.delegate respondsToSelector:self.willStartSelector]) {
        [self.delegate performSelectorOnMainThread:self.willStartSelector withObject:self waitUntilDone:[NSThread isMainThread]];
    }
    
    self.readStream.delegate = self;
    [self.readStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.readStream open];
}

- (void)parseListData:(NSData *)listData {
    
    /*NSMutableArray *newEntries = [NSMutableArray array];
    
    NSUInteger offset = 0;
    NSStringEncoding usedEncoding = 0; // First encoding is 0;
    do {
        CFDictionaryRef thisEntry = nil;
        
        CFIndex bytesConsumed = CFFTPCreateParsedResourceListing(NULL, &((const uint8_t *)listData.bytes)[offset], (CFIndex)([listData length]-offset), &thisEntry);
        if (bytesConsumed > 0) {
            
            // Somtimes CFFTPCreateParsedResourceListing returns a positive number despite the fact that it parsed something. This happens when the parsed data is total bullshit. Thanks, Windows!!!
            
            // So please check for nil.
            if (thisEntry != nil) {
                
                NSDictionary *entryToFix = (NSDictionary *)thisEntry;
                
                // Pull some shit to fix the encoding. Thanks, Apple!!
                
                NSString *newName = nil;
                
                NSString *name = [entryToFix objectForKey:(id)kCFFTPResourceName];
                if (name != nil) {
                    NSData *nameData = [name dataUsingEncoding:NSMacOSRomanStringEncoding];
                    
                    if (nameData.length > 0) {
                        
                        if (usedEncoding) { // The below already got us our encoding
                            newName = [[[NSString alloc]initWithData:nameData encoding:usedEncoding]autorelease];
                        } else { // Hey, lets do some C-style enumeration since we're working with NSStringEncoding (a plain enum) and apple decided to make said enum have erratic numbering, so we can't avoid the fucking C array approach.
                            NSStringEncoding myEncodingToTest[] = { NSUTF8StringEncoding, NSWindowsCP1251StringEncoding, NSWindowsCP1252StringEncoding, NSWindowsCP1253StringEncoding, NSWindowsCP1254StringEncoding, NSWindowsCP1250StringEncoding, NSASCIIStringEncoding, NSUTF16BigEndianStringEncoding, NSUTF16LittleEndianStringEncoding, NSUTF16StringEncoding, NSUTF32BigEndianStringEncoding, NSUTF32LittleEndianStringEncoding, NSUTF32StringEncoding, NSNEXTSTEPStringEncoding, NSJapaneseEUCStringEncoding, NSISOLatin1StringEncoding, NSSymbolStringEncoding, NSNonLossyASCIIStringEncoding, NSShiftJISStringEncoding, NSISOLatin2StringEncoding, NSUnicodeStringEncoding, NSISO2022JPStringEncoding, NSUTF16BigEndianStringEncoding, NSUTF16LittleEndianStringEncoding, NSUTF32StringEncoding, NSUTF32BigEndianStringEncoding, NSUTF32LittleEndianStringEncoding };
                            int howManyEncodings = sizeof(myEncodingToTest)/sizeof(NSStringEncoding);
                            
                            for (int i = 0; (i < howManyEncodings); i++) {
                                
                                NSStringEncoding theEncoding = myEncodingToTest[i];
                                NSString *testString = [[[NSString alloc]initWithData:nameData encoding:theEncoding]autorelease];
                                
                                if (testString.length > 0 && testString != nil) {
                                    newName = testString;
                                    usedEncoding = theEncoding;
                                    break;
                                }
                            }
                        }
                    }
                }
                
                if (newName.length == 0) { // Above failed, fuck it and return unmodified entry
                    NSLog(@"SCRFTPRequest: Name Entry Re-Encoding didn't happen for filename: %@",name); // So you see what's going on.
                    [newEntries addObject:entryToFix];
                } else { // hey it worked! Cool, lets return the fixed one
                    NSMutableDictionary *newEntry = [[entryToFix mutableCopy]autorelease];
                    [newEntry setObject:newName forKey:(id)kCFFTPResourceName];
                    [newEntries addObject:newEntry];
                }
            }
            
            // We consume the bytes regardless of whether we get an entry.
            offset += (NSUInteger)bytesConsumed;
        }
        
        if (thisEntry != nil) {
            CFRelease(thisEntry);
        }
        
        if (bytesConsumed == 0) {
            break;
        } else if (bytesConsumed < 0) {
            // Apple *ahem* we totally failed to parse the listing. Fail.
            [self failWithError:[self constructErrorWithCode:SCRFTPConnectionFailureErrorType message:[NSString stringWithFormat:@"Failed to parse directory contents at %@",self.ftpURL.absoluteString]]];
            break;
        }
    } while (YES);
    
    if (newEntries.count != 0) {
        [self.directoryContents addObjectsFromArray:newEntries];
    }*/
    
	NSUInteger offset = 0;
    
    while (YES) {
        
        CFDictionaryRef entry;
        
        CFIndex length = CFFTPCreateParsedResourceListing(kCFAllocatorDefault, (unsigned char *)listData.bytes+offset, listData.length-offset, &entry);
        
        if (length <= 0 || !entry) {
            break;
        }
        
        if (![(NSString *)CFDictionaryGetValue(entry, kCFFTPResourceName) isEqualToString:@"."] && ![(NSString *)CFDictionaryGetValue(entry, kCFFTPResourceName) isEqualToString:@".."]) {
            
            NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
            
            id name = (NSString *)CFDictionaryGetValue(entry, kCFFTPResourceName);
            
            if (name) {
                [dictionary setObject:name forKey:NSFileName];
                
                int type = [(NSNumber *)CFDictionaryGetValue(entry, kCFFTPResourceType) intValue];
                
                /*
                 * File types from <sys/dirent.h>
                 */
                
                if (type == 0) { // DT_UNKNOWN
                    [dictionary setObject:NSFileTypeUnknown forKey:NSFileType];
                } else if (type == 2) { // DT_CHR
                    [dictionary setObject:NSFileTypeCharacterSpecial forKey:NSFileType];
                } else if (type == 6) { // DT_BLK
                    [dictionary setObject:NSFileTypeBlockSpecial forKey:NSFileType];
                } else if (type == 4) { // DT_DIR
                    [dictionary setObject:NSFileTypeDirectory forKey:NSFileType];
                } else if (type == 8) { // DT_REG
                    [dictionary setObject:NSFileTypeRegular forKey:NSFileType];
                    
                    id size = (NSNumber *)CFDictionaryGetValue(entry, kCFFTPResourceSize);
                    if (size) {
                        [dictionary setObject:size forKey:NSFileSize];
                    }
                    
                } else if (type == 10) { // DT_LNK
                    [dictionary setObject:NSFileTypeSymbolicLink forKey:NSFileType];
                } else if (type == 12) { // DT_SOCK
                    [dictionary setObject:NSFileTypeSocket forKey:NSFileType];
                } 
                
                id date = (NSDate *)CFDictionaryGetValue(entry, kCFFTPResourceModDate);
                if (date) {
                    [dictionary setObject:(NSDate *)date forKey:NSFileModificationDate];
                }
                [self.directoryContents addObject:dictionary];
            }
        }
        
        CFRelease(entry);
        offset += length;
    }
}


#pragma mark Request logic

- (void)applyCredentials {
    
    if (self.operation == SCRFTPRequestOperationDownload || self.operation == SCRFTPRequestOperationListDirectory) {
        if (![self.readStream setProperty:(self.username != nil)?self.username:@"anonymous" forKey:(id)kCFStreamPropertyFTPUserName]) {
            [self failWithError:[self constructErrorWithCode:SCRFTPInternalErrorWhileApplyingCredentialsType message:[NSString stringWithFormat:@"Cannot apply the username \"%@\" to the FTP stream.",self.username]]];
            return;
        }
        if (![self.readStream setProperty:(self.password != nil)?self.password:@"" forKey:(id)kCFStreamPropertyFTPPassword]) {
            [self failWithError:[self constructErrorWithCode:SCRFTPInternalErrorWhileApplyingCredentialsType message:[NSString stringWithFormat:@"Cannot apply the password \"%@\" to the FTP stream.",self.password]]];
            return;
        }
    } else {
        if (self.username) {
            if (![self.writeStream setProperty:self.username forKey:(id)kCFStreamPropertyFTPUserName]) {
                [self failWithError:[self constructErrorWithCode:SCRFTPInternalErrorWhileApplyingCredentialsType message:[NSString stringWithFormat:@"Cannot apply the username \"%@\" to the FTP stream.",self.username]]];
                return;
            }
            if (![self.writeStream setProperty:self.password forKey:(id)kCFStreamPropertyFTPPassword]) {
                [self failWithError:[self constructErrorWithCode:SCRFTPInternalErrorWhileApplyingCredentialsType message:[NSString stringWithFormat:NSLocalizedString(@"Cannot apply the password \"%@\" to the FTP stream.", @""),self.password]]];
                return;
            }
        }
    }
}

- (void)cancel {
	
	[[self cancelledLock]lock];
	
	if ([self isComplete] || [self isCancelled]) {
		return;
	}
	
	[self cancelRequest];
	
	[[self cancelledLock]unlock];
	
	[super cancel];
}

- (void)main {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
	
	[[self cancelledLock]lock];
	
	[self startRequest];
	[self resetTimeout];
	
	[[self cancelledLock]unlock];
	
	while (![self isCancelled] && ![self isComplete]) {
		
		[[self cancelledLock]lock];
		
		if ([[self timeOutDate]timeIntervalSinceNow] <= 0) {
			[self failWithError:SCRFTPRequestTimedOutError];
			break;
		}
		
		[[self cancelledLock]unlock];
		
		[[NSRunLoop currentRunLoop]runMode:NSDefaultRunLoopMode beforeDate:[self timeOutDate]];
	}
	
	[pool release];
}

- (void)resetTimeout{
	[self setTimeOutDate:[NSDate dateWithTimeIntervalSinceNow:[self timeOutSeconds]]];
}

- (void)cancelRequest {
	[self failWithError:SCRFTPRequestCancelledError];
}

- (void)startRequest {
	
	_complete = NO;
	_fileSize = 0;
	_bytesWritten = 0;
	_status = SCRFTPRequestStatusNone;
	
	switch (self.operation) {
		case SCRFTPRequestOperationUpload:
			[self startUploadRequest];
			break;
		case SCRFTPRequestOperationCreateDirectory:
			[self startCreateDirectoryRequest];
			break;
        case SCRFTPRequestOperationDownload:
            [self startDownloadRequest];
            break;
        case SCRFTPRequestOperationListDirectory:
            [self startListDirectoriesRequest];
            break;
	}
}

- (void)startAsynchronous {
	[[SCRFTPRequest sharedRequestQueue]addOperation:self];
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {
	[self resetTimeout];
	
	switch (self.operation) {
		case SCRFTPRequestOperationUpload:
			[self handleUploadEvent:eventCode];
			break;
		case SCRFTPRequestOperationCreateDirectory:
			[self handleCreateDirectoryEvent:eventCode];
			break;
        case SCRFTPRequestOperationDownload:
            [self handleDownloadEvent:eventCode];
            break;
        case SCRFTPRequestOperationListDirectory:
            [self handleListEvent:eventCode];
            break;
	}
}

#pragma mark Download logic

- (void)handleDownloadEvent:(NSStreamEvent)eventCode {
    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            [self setStatus:SCRFTPRequestStatusOpenNetworkConnection];
        } break;
        case NSStreamEventHasBytesAvailable: {
            uint8_t buffer[32768];
            
            [self setStatus:SCRFTPRequestStatusReadingFromStream];
            
            NSInteger bytesRead = [self.readStream read:buffer maxLength:sizeof(buffer)];
            
            if (bytesRead == -1) {
                [self failWithError:[self constructErrorWithCode:SCRFTPConnectionFailureErrorType message:[NSString stringWithFormat:@"Cannot continue downloading the file at %@",self.ftpURL.absoluteString]]];
                return;
            } else if (bytesRead == 0) {
                [self requestFinished];
            } else {
                NSInteger bytesWritten;
                NSInteger bytesWrittenSoFar = 0;
                
                do {
                    bytesWritten = [self.writeStream write:&buffer[bytesWrittenSoFar] maxLength:(NSUInteger)(bytesRead-bytesWrittenSoFar)];
                    assert(bytesWritten != 0);
                    if (bytesWritten == -1) {
                        [self failWithError:[self constructErrorWithCode:SCRFTPConnectionFailureErrorType message:[NSString stringWithFormat:@"Cannot continue writing data to the local file at %@",self.filePath]]];
                        return;
                        break;
                    } else {
                        bytesWrittenSoFar += bytesWritten;
                        [self setStatus:SCRFTPRequestStatusWritingToStream];
                    }
                } while (bytesWrittenSoFar != bytesRead);
            }
        } break;
        case NSStreamEventHasSpaceAvailable: {
            assert(NO); // should never happen for the output stream
        } break;
        case NSStreamEventErrorOccurred: {
            CFStreamError err = CFReadStreamGetError((CFReadStreamRef)self.readStream);
            if (err.domain == kCFStreamErrorDomainFTP) {
                [self failWithError:[self constructErrorWithCode:SCRFTPConnectionFailureErrorType message:[NSString stringWithFormat:@"FTP error %d", (int)err.error]]];
            } else {
				[self failWithError:[self constructErrorWithCode:SCRFTPConnectionFailureErrorType message:@"Cannot open FTP connection."]];
            }
        } break;
        case NSStreamEventEndEncountered: {
            // ignore
        } break;
        default: {
            assert(NO);
        } break;
    }
}

- (void)startDownloadRequest {
    
    if (!self.ftpURL || !self.filePath) {
		[self failWithError:SCRFTPUnableToCreateRequestError];
		return;
	}
    
    self.writeStream = [NSOutputStream outputStreamToFileAtPath:self.filePath append:NO];
    [self.writeStream open];
    
    CFReadStreamRef readStreamTemp = CFReadStreamCreateWithFTPURL(kCFAllocatorDefault, (CFURLRef)self.ftpURL);
    if (!readStreamTemp) {
        [self failWithError:[self constructErrorWithCode:SCRFTPUnableToCreateRequestErrorType message:[NSString stringWithFormat:@"Cannot open FTP connection to %@",self.ftpURL]]];
        return;
    }
    
    if (self.willStartSelector && [self.delegate respondsToSelector:self.willStartSelector]) {
        [self.delegate performSelectorOnMainThread:self.willStartSelector withObject:self waitUntilDone:[NSThread isMainThread]];
    }
    
    self.readStream = (NSInputStream *)readStreamTemp;
    CFRelease(readStreamTemp);
    [self applyCredentials];
    self.readStream.delegate = self;
    [self.readStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.readStream open];
}

#pragma mark Upload logic

- (void)startUploadRequest {
	
	if (!self.ftpURL || !self.filePath) {
		[self failWithError:SCRFTPUnableToCreateRequestError];
		return;
	}
	
	CFStringRef fileName = self.customUploadFileName?(CFStringRef)self.customUploadFileName:(CFStringRef)[self.filePath lastPathComponent];
	if (!fileName) {
		[self failWithError:[self constructErrorWithCode:SCRFTPInternalErrorWhileBuildingRequestType message:[NSString stringWithFormat:@"Unable to retrieve file name from file located at %@",self.filePath]]];
		return;
	}
	
	CFURLRef uploadUrl = CFURLCreateCopyAppendingPathComponent(kCFAllocatorDefault, (CFURLRef)self.ftpURL, fileName, false);
	if (!uploadUrl) {
		[self failWithError:[self constructErrorWithCode:SCRFTPInternalErrorWhileBuildingRequestType message:@"Unable to build URL to upload."]];
		return;
	}
	
	NSError *attributesError = nil;
	NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.filePath error:&attributesError];
	if (attributesError) {
		[self failWithError:attributesError];
        CFRelease(uploadUrl); //added this line to fix analyze warning saying that uploadURL wasn't being release...
		return;
	} else {
		_fileSize = [fileAttributes fileSize];
		if (self.willStartSelector && [self.delegate respondsToSelector:self.willStartSelector]) {
			[self.delegate performSelectorOnMainThread:self.willStartSelector withObject:self waitUntilDone:[NSThread isMainThread]];
		}
	}
	
	self.readStream = [NSInputStream inputStreamWithFileAtPath:self.filePath];
	if (!self.readStream) {
		[self failWithError:
		 [self constructErrorWithCode:SCRFTPUnableToCreateRequestErrorType message:[NSString stringWithFormat:@"Cannot start reading the file located at %@ (bad path?).",self.filePath]]];
        CFRelease(uploadUrl); //added this line to fix analyze warning saying that uploadURL wasn't being release...
		return;
	}
	
	[self.readStream open];
	
	CFWriteStreamRef uploadStream = CFWriteStreamCreateWithFTPURL(NULL, uploadUrl);
	if (!uploadStream) {
		[self failWithError:[self constructErrorWithCode:SCRFTPUnableToCreateRequestErrorType message:[NSString stringWithFormat:@"Cannot open FTP connection to %@",(NSURL *)uploadUrl]]];
		CFRelease(uploadUrl);
		return;
	}
	CFRelease(uploadUrl);
	
	self.writeStream = (NSOutputStream *)uploadStream;
	[self applyCredentials];
	self.writeStream.delegate = self;
	[self.writeStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[self.writeStream open];
	
	CFRelease(uploadStream);
}

- (void)handleUploadEvent:(NSStreamEvent)eventCode {
	
	switch (eventCode) {
        case NSStreamEventOpenCompleted: {
			[self setStatus:SCRFTPRequestStatusOpenNetworkConnection];
        } break;
        case NSStreamEventHasSpaceAvailable: {
			
            /* If we don't have any data buffered, go read the next chunk of data. */
            if (_bufferOffset == _bufferLimit) {
				
				[self setStatus:SCRFTPRequestStatusReadingFromStream];
                NSInteger bytesRead = [self.readStream read:_buffer maxLength:kSCRFTPRequestBufferSize];
                if (bytesRead == -1) {
					[self failWithError:[self constructErrorWithCode:SCRFTPConnectionFailureErrorType message:[NSString stringWithFormat:@"Cannot continue reading the file at %@",self.filePath]]];
					return;
				} else if (bytesRead == 0) {
					[self requestFinished];
					return;
                } else {
                    _bufferOffset = 0;
                    _bufferLimit = bytesRead;
                }
            }
            
            if (_bufferOffset != _bufferLimit) {
				
                _bytesWritten = [self.writeStream write:&_buffer[_bufferOffset] maxLength:_bufferLimit - _bufferOffset];
                assert(_bytesWritten != 0);
                
				if (_bytesWritten == -1) {
					
					[self failWithError:[self constructErrorWithCode:SCRFTPConnectionFailureErrorType message:@"Cannot continue writing file to the specified URL at the FTP server."]];
					return;
                } else {
					
					[self setStatus:SCRFTPRequestStatusWritingToStream];
					
					if (self.bytesWrittenSelector && [self.delegate respondsToSelector:self.bytesWrittenSelector]) {
						[self.delegate performSelectorOnMainThread:self.bytesWrittenSelector withObject:self waitUntilDone:[NSThread isMainThread]];
					}
					
                    _bufferOffset += _bytesWritten;
                }
            }
        } break;
        case NSStreamEventErrorOccurred: {
			[self failWithError:[self constructErrorWithCode:SCRFTPConnectionFailureErrorType message:@"Cannot open FTP connection."]];
        } break;
        case NSStreamEventEndEncountered: {
			/* Ignore */
        } break;
        default: {
            assert(NO);
        } break;
    }
}

- (void)startCreateDirectoryRequest {
	
	if (!self.ftpURL || !self.directoryName) {
		[self failWithError:SCRFTPUnableToCreateRequestError];
		return;
	}
	
	CFURLRef createUrl = CFURLCreateCopyAppendingPathComponent(NULL, (CFURLRef)self.ftpURL, (CFStringRef)self.directoryName, true);
	if (!createUrl) {
		[self failWithError:[self constructErrorWithCode:SCRFTPInternalErrorWhileBuildingRequestType message:@"Unable to build URL to create directory."]];
		return;
	}
	
	CFWriteStreamRef createStream = CFWriteStreamCreateWithFTPURL(NULL, createUrl);
	if (!createStream) {
		[self failWithError:[self constructErrorWithCode:SCRFTPUnableToCreateRequestErrorType message:[NSString stringWithFormat:@"Cannot open FTP connection to %@",(NSURL *)createUrl]]];
		CFRelease(createUrl);
		return;
	}
	CFRelease(createUrl);
	
	self.writeStream = (NSOutputStream *)createStream;
	[self applyCredentials];
	self.writeStream.delegate = self;
	[self.writeStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[self.writeStream open];
	
	CFRelease(createStream);
}

- (void)handleCreateDirectoryEvent:(NSStreamEvent)eventCode {
	
	switch (eventCode) {
        case NSStreamEventOpenCompleted: {
			[self setStatus:SCRFTPRequestStatusOpenNetworkConnection];
        } break;
        case NSStreamEventHasBytesAvailable: {
            assert(NO); /* Should never happen for the output stream. */
        } break;
        case NSStreamEventHasSpaceAvailable: {
            assert(NO);
        } break;
        case NSStreamEventErrorOccurred: {
			CFStreamError err = CFWriteStreamGetError((CFWriteStreamRef)self.writeStream);
            if (err.domain == kCFStreamErrorDomainFTP) {
                [self failWithError:[self constructErrorWithCode:SCRFTPConnectionFailureErrorType message:[NSString stringWithFormat:@"FTP error %d", (int)err.error]]];
            } else {
				[self failWithError:[self constructErrorWithCode:SCRFTPConnectionFailureErrorType message:@"Cannot open FTP connection."]];
            }
        } break;
        case NSStreamEventEndEncountered: {
			[self requestFinished];
        } break;
        default: {
            assert(NO);
        } break;
    }	
}

#pragma mark Complete / Failure

- (NSError *)constructErrorWithCode:(NSInteger)code message:(NSString *)message {
	return [NSError errorWithDomain:SCRFTPRequestErrorDomain code:code userInfo:[NSDictionary dictionaryWithObjectsAndKeys:message,NSLocalizedDescriptionKey, nil]];
}

- (BOOL)isComplete {
	return _complete;
}

- (BOOL)isFinished {
	return [self isComplete];
}

- (void)requestFinished {
	_complete = YES;
	[self cleanUp];
	
	[self setStatus:SCRFTPRequestStatusClosedNetworkConnection];
	
	if (self.didFinishSelector && [self.delegate respondsToSelector:self.didFinishSelector]) {
		[self.delegate performSelectorOnMainThread:self.didFinishSelector withObject:self waitUntilDone:[NSThread isMainThread]];
	}
}

- (void)failWithError:(NSError *)error {
	
	_complete = YES;
	
	if (self.error != nil || [self isCancelled]) {
		return;
	}
	
	self.error = error;
	[self cleanUp];
	[self setStatus:SCRFTPRequestStatusError];
	
	if (self.didFailSelector && [self.delegate respondsToSelector:self.didFailSelector]) {
		[self.delegate performSelectorOnMainThread:self.didFailSelector withObject:self waitUntilDone:[NSThread isMainThread]];
	}
}

- (void)cleanUp {
	if (self.writeStream != nil) {
        [self.writeStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.writeStream.delegate = nil;
        [self.writeStream close];
        self.writeStream = nil;
    }
    if (self.readStream != nil) {
        [self.readStream close];
        self.readStream = nil;
    }
}

+ (NSOperationQueue *)sharedRequestQueue {
	if (!sharedRequestQueue) {
		sharedRequestQueue = [[NSOperationQueue alloc]init];
		[sharedRequestQueue setMaxConcurrentOperationCount:4];
	}
	return sharedRequestQueue;
}

- (void)dealloc {
    NSLog(@"SCRFTPRequest: kthnxbye");
    [self setDirectoryContents:nil];
    [self setDelegate:nil];
    [self setError:nil];
    [self setUserInfo:nil];
    [self setUsername:nil];
    [self setPassword:nil];
    [self setFtpURL:nil];
    [self setCustomUploadFileName:nil];
    [self setFilePath:nil];
    [self setDirectoryName:nil];
    [self setWriteStream:nil];
    [self setReadStream:nil];
    [self setTimeOutDate:nil];
    [self setCancelledLock:nil];
    [super dealloc];
}

@end
