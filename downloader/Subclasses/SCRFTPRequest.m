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

NSString * const SCRFTPRequestErrorDomain = @"SCRFTPRequestErrorDomain";
NSString * const NSFileName  = @"NSFileName";

static NSOperationQueue *sharedRequestQueue = nil;

@interface SCRFTPRequest () <NSStreamDelegate> {
    UInt8 _buffer[kSCRFTPRequestBufferSize];
    UInt32 _bufferOffset;
    UInt32 _bufferLimit;
}

@property (nonatomic, retain) NSOutputStream *writeStream;
@property (nonatomic, retain) NSInputStream *readStream;
@property (nonatomic, retain) NSDate *timeOutDate;
@property (nonatomic, retain) NSRecursiveLock *cancelledLock;

@property (nonatomic, assign) BOOL complete;
@property (nonatomic, assign) UInt64 fileSize;
@property (nonatomic, assign) SInt64 bytesWritten;
@property (nonatomic, assign) SCRFTPRequestStatus status;

- (void)applyCredentials;
- (void)cleanUp;
- (NSError *)constructErrorWithCode:(NSInteger)code message:(NSString *)message;
- (void)failWithError:(NSError *)error;
- (void)initializeComponentWithURL:(NSURL *)ftpURL operation:(SCRFTPRequestOperation)operation;
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

- (void)setStatus:(SCRFTPRequestStatus)status {
	if (_status != status) {
		_status = status;
		if (self.didChangeStatusSelector && [self.delegate respondsToSelector:self.didChangeStatusSelector]) {
			[self.delegate performSelectorOnMainThread:self.didChangeStatusSelector withObject:self waitUntilDone:[NSThread isMainThread]];
		}
	}
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

- (void)startListDirectoriesRequest {
    
    if (!_ftpURL) {
		[self failWithError:[self constructErrorWithCode:SCRFTPUnableToCreateRequestErrorType message:@"Unable to create request (bad url?)"]];
		return;
	}
    
    self.directoryContents = [NSMutableArray array];
    
    CFReadStreamRef readStreamRef = CFReadStreamCreateWithFTPURL(kCFAllocatorDefault, (CFURLRef)self.ftpURL);
    
    if (!readStreamRef) {
        [self failWithError:[self constructErrorWithCode:SCRFTPUnableToCreateRequestErrorType message:[NSString stringWithFormat:@"Cannot open FTP connection to %@",_ftpURL]]];
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
                    [dictionary setObject:[NSNumber numberWithFloat:[(NSDate *)date timeIntervalSince1970]] forKey:NSFileModificationDate];
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
    
    if (_operation == SCRFTPRequestOperationDownload || _operation == SCRFTPRequestOperationListDirectory) {
        if (![_readStream setProperty:(_username != nil)?_username:@"anonymous" forKey:(id)kCFStreamPropertyFTPUserName]) {
            [self failWithError:[self constructErrorWithCode:SCRFTPInternalErrorWhileApplyingCredentialsType message:[NSString stringWithFormat:@"Cannot apply the username \"%@\" to the FTP stream.",_username]]];
            return;
        }
        if (![_readStream setProperty:(_password != nil)?_password:@"" forKey:(id)kCFStreamPropertyFTPPassword]) {
            [self failWithError:[self constructErrorWithCode:SCRFTPInternalErrorWhileApplyingCredentialsType message:[NSString stringWithFormat:@"Cannot apply the password \"%@\" to the FTP stream.",_password]]];
            return;
        }
    } else {
        if (_username) {
            if (![_writeStream setProperty:_username forKey:(id)kCFStreamPropertyFTPUserName]) {
                [self failWithError:[self constructErrorWithCode:SCRFTPInternalErrorWhileApplyingCredentialsType message:[NSString stringWithFormat:@"Cannot apply the username \"%@\" to the FTP stream.",_username]]];
                return;
            }
            if (![_writeStream setProperty:_password forKey:(id)kCFStreamPropertyFTPPassword]) {
                [self failWithError:[self constructErrorWithCode:SCRFTPInternalErrorWhileApplyingCredentialsType message:[NSString stringWithFormat:@"Cannot apply the password \"%@\" to the FTP stream.",_password]]];
                return;
            }
        }
    }
}

- (void)cancel {
	if (_complete || self.isCancelled) {
		return;
	}
    
    [[self cancelledLock]lock];
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
	
	while (!self.isCancelled && !_complete) {
		
		[[self cancelledLock]lock];
		
		if ([[self timeOutDate]timeIntervalSinceNow] <= 0) {
			[self failWithError:[self constructErrorWithCode:SCRFTPRequestTimedOutErrorType message:@"The request timed out."]];
            [[self cancelledLock]unlock];
			break;
		}
		
		[[self cancelledLock]unlock];
		
		[[NSRunLoop currentRunLoop]runMode:NSDefaultRunLoopMode beforeDate:self.timeOutDate];
	}
	
	[pool release];
}

- (void)resetTimeout{
	[self setTimeOutDate:[NSDate dateWithTimeIntervalSinceNow:[self timeOutSeconds]]];
}

- (void)cancelRequest {
	[self failWithError:[self constructErrorWithCode:SCRFTPRequestCancelledErrorType message:@"The request was cancelled."]];
}

- (void)startRequest {
	
	_complete = NO;
	_fileSize = 0;
	_bytesWritten = 0;
	_status = SCRFTPRequestStatusNone;
	
	switch (_operation) {
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
	
	switch (_operation) {
		case SCRFTPRequestOperationUpload: {
			[self handleUploadEvent:eventCode];
        } break;
		case SCRFTPRequestOperationCreateDirectory: {
			[self handleCreateDirectoryEvent:eventCode];
        } break;
        case SCRFTPRequestOperationDownload: {
            [self handleDownloadEvent:eventCode];
        } break;
        case SCRFTPRequestOperationListDirectory: {
            [self handleListEvent:eventCode];
        } break;
        default: {
        } break;
	}
}

#pragma mark Download logic

- (void)handleDownloadEvent:(NSStreamEvent)eventCode {
    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            [self setStatus:SCRFTPRequestStatusOpenNetworkConnection];
        } break;
        case NSStreamEventHasBytesAvailable: {
            uint8_t buffer[kSCRFTPRequestBufferSize];
            
            [self setStatus:SCRFTPRequestStatusReadingFromStream];
            
            NSInteger bytesRead = [_readStream read:buffer maxLength:sizeof(buffer)];
            
            if (bytesRead == -1) {
                [self failWithError:[self constructErrorWithCode:SCRFTPConnectionFailureErrorType message:[NSString stringWithFormat:@"Cannot continue downloading the file at %@",_ftpURL.absoluteString]]];
                return;
            } else if (bytesRead == 0) {
                [self requestFinished];
            } else {
                NSInteger bytesWritten;
                NSInteger bytesWrittenSoFar = 0;
                
                do {
                    bytesWritten = [_writeStream write:&buffer[bytesWrittenSoFar] maxLength:(NSUInteger)(bytesRead-bytesWrittenSoFar)];
                    if (bytesWritten == -1) {
                        [self failWithError:[self constructErrorWithCode:SCRFTPConnectionFailureErrorType message:[NSString stringWithFormat:@"Cannot continue writing data to the local file at %@",_filePath]]];
                        return;
                        break;
                    } else {
                        bytesWrittenSoFar += bytesWritten;
                        [self setStatus:SCRFTPRequestStatusWritingToStream];
                        
                        if (_bytesWrittenSelector && [_delegate respondsToSelector:_bytesWrittenSelector]) {
                            [_delegate performSelectorOnMainThread:_bytesWrittenSelector withObject:self waitUntilDone:[NSThread isMainThread]];
                        }
                        
                    }
                } while (bytesWrittenSoFar != bytesRead);
            }
        } break;
        case NSStreamEventErrorOccurred: {
            CFStreamError err = CFReadStreamGetError((CFReadStreamRef)self.readStream);
            if (err.domain == kCFStreamErrorDomainFTP) {
                [self failWithError:[self constructErrorWithCode:SCRFTPConnectionFailureErrorType message:[NSString stringWithFormat:@"FTP error %d", (int)err.error]]];
            } else {
				[self failWithError:[self constructErrorWithCode:SCRFTPConnectionFailureErrorType message:@"Cannot open FTP connection."]];
            }
        } break;
        default: {
        } break;
    }
}

- (void)startDownloadRequest {
    
    if (!(_ftpURL && _filePath)) {
        [self failWithError:[self constructErrorWithCode:SCRFTPUnableToCreateRequestErrorType message:@"Unable to create request (bad url?)"]];
		return;
	}
    
    self.writeStream = [NSOutputStream outputStreamToFileAtPath:_filePath append:NO];
    [_writeStream open];
    
    CFReadStreamRef readStreamTemp = CFReadStreamCreateWithFTPURL(kCFAllocatorDefault, (CFURLRef)_ftpURL);
    if (!readStreamTemp) {
        [self failWithError:[self constructErrorWithCode:SCRFTPUnableToCreateRequestErrorType message:[NSString stringWithFormat:@"Cannot open FTP connection to %@",_ftpURL]]];
        return;
    }
    
    if (_willStartSelector && [_delegate respondsToSelector:_willStartSelector]) {
        [_delegate performSelectorOnMainThread:_willStartSelector withObject:self waitUntilDone:[NSThread isMainThread]];
    }
    
    self.readStream = (NSInputStream *)readStreamTemp;
    CFRelease(readStreamTemp);
    [self applyCredentials];
    _readStream.delegate = self;
    [_readStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_readStream open];
}

#pragma mark Upload logic

- (void)startUploadRequest {
	if (!(_ftpURL && _filePath)) {
		[self failWithError:[self constructErrorWithCode:SCRFTPUnableToCreateRequestErrorType message:@"Unable to create request (bad url?)"]];
		return;
	}
	
	CFStringRef fileName = _customUploadFileName?(CFStringRef)_customUploadFileName:(CFStringRef)[_filePath lastPathComponent];
	if (!fileName) {
		[self failWithError:[self constructErrorWithCode:SCRFTPInternalErrorWhileBuildingRequestType message:[NSString stringWithFormat:@"Unable to retrieve file name from file located at %@",self.filePath]]];
		return;
	}

	NSError *attributesError = nil;
	NSDictionary *fileAttributes = [[NSFileManager defaultManager]attributesOfItemAtPath:_filePath error:&attributesError];
	if (attributesError) {
		[self failWithError:attributesError];
		return;
	} else {
		_fileSize = fileAttributes.fileSize;
		if (_willStartSelector && [_delegate respondsToSelector:_willStartSelector]) {
			[_delegate performSelectorOnMainThread:_willStartSelector withObject:self waitUntilDone:[NSThread isMainThread]];
		}
	}
	
	self.readStream = [NSInputStream inputStreamWithFileAtPath:_filePath];
	if (!_readStream) {
		[self failWithError:[self constructErrorWithCode:SCRFTPUnableToCreateRequestErrorType message:[NSString stringWithFormat:@"Cannot start reading the file located at %@ (bad path?).",_filePath]]];
		return;
	}
	
	[_readStream open];
    
    CFURLRef uploadUrl = CFURLCreateCopyAppendingPathComponent(kCFAllocatorDefault, (CFURLRef)_ftpURL, fileName, NO);
	if (!uploadUrl) {
		[self failWithError:[self constructErrorWithCode:SCRFTPInternalErrorWhileBuildingRequestType message:@"Unable to build URL to upload."]];
		return;
	}
	
	CFWriteStreamRef uploadStream = CFWriteStreamCreateWithFTPURL(kCFAllocatorDefault, uploadUrl);
    CFRelease(uploadUrl);
	if (!uploadStream) {
		[self failWithError:[self constructErrorWithCode:SCRFTPUnableToCreateRequestErrorType message:[NSString stringWithFormat:@"Cannot open FTP connection to %@",(NSURL *)uploadUrl]]];
		return;
	}
	
	self.writeStream = (NSOutputStream *)uploadStream;
	[self applyCredentials];
	_writeStream.delegate = self;
	[_writeStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_writeStream open];
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
				
                _bytesWritten = [_writeStream write:&_buffer[_bufferOffset] maxLength:_bufferLimit-_bufferOffset];
                
				if (_bytesWritten == -1) {
					[self failWithError:[self constructErrorWithCode:SCRFTPConnectionFailureErrorType message:@"Cannot continue writing file to the specified URL at the FTP server."]];
					return;
                } else {
					[self setStatus:SCRFTPRequestStatusWritingToStream];
					
					if (_bytesWrittenSelector && [_delegate respondsToSelector:_bytesWrittenSelector]) {
						[_delegate performSelectorOnMainThread:_bytesWrittenSelector withObject:self waitUntilDone:[NSThread isMainThread]];
					}
					
                    _bufferOffset += _bytesWritten;
                }
            }
        } break;
        case NSStreamEventErrorOccurred: {
			[self failWithError:[self constructErrorWithCode:SCRFTPConnectionFailureErrorType message:@"Cannot open FTP connection."]];
        } break;
        default: {
        } break;
    }
}

- (void)startCreateDirectoryRequest {
	
	if ((!_ftpURL || !_directoryName) || (!_ftpURL && !_directoryName)) {
		[self failWithError:[self constructErrorWithCode:SCRFTPUnableToCreateRequestErrorType message:@"Unable to create request (bad url?)"]];
		return;
	}
	
	CFURLRef createUrl = CFURLCreateCopyAppendingPathComponent(kCFAllocatorDefault, (CFURLRef)_ftpURL, (CFStringRef)_directoryName, YES);
	if (!createUrl) {
		[self failWithError:[self constructErrorWithCode:SCRFTPInternalErrorWhileBuildingRequestType message:@"Unable to build URL to create directory."]];
		return;
	}
	
	CFWriteStreamRef createStream = CFWriteStreamCreateWithFTPURL(kCFAllocatorDefault, createUrl);
    CFRelease(createUrl);
    
	if (!createStream) {
		[self failWithError:[self constructErrorWithCode:SCRFTPUnableToCreateRequestErrorType message:[NSString stringWithFormat:@"Cannot open FTP connection to %@",(NSURL *)createUrl]]];
		return;
	}
	
	self.writeStream = (NSOutputStream *)createStream;
	[self applyCredentials];
	_writeStream.delegate = self;
	[_writeStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_writeStream open];
	
	CFRelease(createStream);
}

- (void)handleCreateDirectoryEvent:(NSStreamEvent)eventCode {
	switch (eventCode) {
        case NSStreamEventOpenCompleted: {
			[self setStatus:SCRFTPRequestStatusOpenNetworkConnection];
        } break;
        case NSStreamEventErrorOccurred: {
			CFStreamError err = CFWriteStreamGetError((CFWriteStreamRef)_writeStream);
            if (err.domain == kCFStreamErrorDomainFTP) {
                [self failWithError:[self constructErrorWithCode:SCRFTPConnectionFailureErrorType message:[NSString stringWithFormat:@"FTP error %d",(int)err.error]]];
            } else {
				[self failWithError:[self constructErrorWithCode:SCRFTPConnectionFailureErrorType message:@"Cannot open FTP connection."]];
            }
        } break;
        case NSStreamEventEndEncountered: {
			[self requestFinished];
        } break;
        default: {
        } break;
    }	
}

- (NSError *)constructErrorWithCode:(NSInteger)code message:(NSString *)message {
	return [NSError errorWithDomain:SCRFTPRequestErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey: message}];
}

- (void)requestFinished {
	self.complete = YES;
	[self cleanUp];
	
	[self setStatus:SCRFTPRequestStatusClosedNetworkConnection];
	
	if (_didFinishSelector && [_delegate respondsToSelector:_didFinishSelector]) {
		[_delegate performSelectorOnMainThread:_didFinishSelector withObject:self waitUntilDone:[NSThread isMainThread]];
	}
}

- (void)failWithError:(NSError *)error {
	
	self.complete = YES;
	
	if (_error != nil || self.isCancelled) {
		return;
	}
	
	self.error = error;
	[self cleanUp];
	[self setStatus:SCRFTPRequestStatusError];
	
	if (_didFailSelector && [_delegate respondsToSelector:_didFailSelector]) {
		[_delegate performSelectorOnMainThread:_didFailSelector withObject:self waitUntilDone:[NSThread isMainThread]];
	}
}

- (void)cleanUp {
	if (_writeStream != nil) {
        [_writeStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        _writeStream.delegate = nil;
        [_writeStream close];
        self.writeStream = nil;
    }
    if (_readStream != nil) {
        [_readStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        _readStream.delegate = nil;
        [_readStream close];
        self.readStream = nil;
    }
}

+ (NSOperationQueue *)sharedRequestQueue {
	if (!sharedRequestQueue) {
		sharedRequestQueue = [[NSOperationQueue alloc]init];
        sharedRequestQueue.maxConcurrentOperationCount = 4;
	}
	return sharedRequestQueue;
}

- (void)dealloc {
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
