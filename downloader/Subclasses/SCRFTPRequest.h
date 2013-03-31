//
//  SCRFTPRequest.h
//  SCRFtpClient
//
//  Created by Aleks Nesterow on 10/28/09.
//  aleks.nesterow@gmail.com
//	
//	Inspired by http://allseeing-i.com/ASIHTTPRequest/
//	Was using code samples from http://developer.apple.com/iphone/library/samplecode/SimpleFTPSample/index.html
//	and http://developer.apple.com/mac/library/samplecode/CFFTPSample/index.html
//  
//  Copyright © 2009, 7touch Group, Inc.
//  All rights reserved.
//  
//  Purpose:
//  Performs requests to a FTP server and allows to list directories on the FTP server, create new directories, download and upload files.
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

#define NSFileName @"NSFileName"

#if TARGET_IPHONE
	#import <CFNetwork/CFNetwork.h>
#endif
#import <Foundation/Foundation.h>
#import <stdio.h>

typedef enum {
	SCRFTPRequestOperationDownload,
	SCRFTPRequestOperationUpload,
	SCRFTPRequestOperationCreateDirectory,
    SCRFTPRequestOperationListDirectory
} SCRFTPRequestOperation;

typedef enum {
    SCRFTPConnectionFailureErrorType = 1,
    SCRFTPRequestTimedOutErrorType = 2,
    SCRFTPAuthenticationErrorType = 3,
    SCRFTPRequestCancelledErrorType = 4,
	SCRFTPUnableToCreateRequestErrorType = 5,
	SCRFTPInternalErrorWhileBuildingRequestType  = 6,
    SCRFTPInternalErrorWhileApplyingCredentialsType  = 7
} SCRFTPRequestErrorType;

typedef enum {
	SCRFTPRequestStatusNone,
	SCRFTPRequestStatusOpenNetworkConnection,
	SCRFTPRequestStatusReadingFromStream,
	SCRFTPRequestStatusWritingToStream,
	SCRFTPRequestStatusClosedNetworkConnection,
	SCRFTPRequestStatusError
} SCRFTPRequestStatus;

/* When using file streams, the 32KB buffer is probably not enough.
 * A good way to establish a buffer size is to increase it over time.
 * If every read consumes the entire buffer, start increasing the buffer
 * size, and at some point you would then cap it. 32KB is fine for network
 * sockets, although using the technique described above is still a good idea.
 */
#define kSCRFTPRequestBufferSize 32768

/* The error domain that all errors generated by SCRFTPRequest use. */
extern NSString *const SCRFTPRequestErrorDomain;

@interface SCRFTPRequest : NSOperation <NSStreamDelegate> {
	
@private
	BOOL _complete;
	
	/* State */
	
	NSOutputStream *_writeStream;
	NSInputStream *_readStream;
	UInt8 _buffer[kSCRFTPRequestBufferSize];
	UInt32 _bufferOffset;
	UInt32 _bufferLimit;
	
	/* For properties */
	
	id _delegate;
	SEL _didFinishSelector;
	SEL _didFailSelector;
	SEL _willStartSelector;
	SEL _didChangeStatusSelector;
	SEL _bytesWrittenSelector;
	
	UInt64 _fileSize;
	SInt64 _bytesWritten;
	SCRFTPRequestStatus _status;
	NSError *_error;
	
	SCRFTPRequestOperation _operation;
	
	NSTimeInterval _timeOutSeconds;
	
	NSDictionary *_userInfo;
	
	NSString *_username;
	NSString *_password;
	
	NSURL *_ftpURL;
	NSString *_filePath;
	NSString *_directoryName;
	
	NSDate *_timeOutDate;
	
	NSRecursiveLock *_cancelledLock;
	
}

@property (nonatomic, assign) id delegate;
/** Called on the delegate when the request completes successfully. */
@property (nonatomic, assign) SEL didFinishSelector;
/** Called on the delegate when the request fails. */
@property (nonatomic, assign) SEL didFailSelector;
/** Called on the delegate when the transfer is about to start. */
@property (nonatomic, assign) SEL willStartSelector;
/** Called on the delegate when the status of the request instance changed. */
@property (nonatomic, assign) SEL didChangeStatusSelector;
/** Called on the delegate when some amount of bytes were transferred. */
@property (nonatomic, assign) SEL bytesWrittenSelector;

/** If 0 the size cannot be determined. fileSize is determined when delegate receives a notification via willStartSelector. */
@property (nonatomic, readonly) UInt64 fileSize;
/** The amount of bytes currently uploaded or downloaded. Delegate can listen to the changes of this property via bytesWrittenSelector. */
@property (nonatomic, readonly) SInt64 bytesWritten;
/** Current instance status. Delegate can listen to the changes of this property via didChangeStatusSelector. */
@property (nonatomic, readonly) SCRFTPRequestStatus status;
/** Populated when error occurs. */
@property (nonatomic, retain) NSError *error;

/** Specifies the operation for the request to invoke. */
@property (nonatomic, assign) SCRFTPRequestOperation operation;

/** In this dictionary you can pass any state info you need. */
@property (nonatomic, retain) NSDictionary *userInfo;

/** Username for authentication. */
@property (nonatomic, copy) NSString *username;
/** Password for authentication. */
@property (nonatomic, copy) NSString *password;

/** The url for this operation. */
@property (nonatomic, retain) NSURL *ftpURL;
/** A custom upload file name */
@property (nonatomic, copy) NSString *customUploadFileName;
/** Specifies the file to upload or to write the downloaded data to. */
@property (nonatomic, copy) NSString *filePath;
/** Denotes the directory to create. Specified when operation is SCRFTPRequestOperationCreateDirectory. */
@property (nonatomic, copy) NSString *directoryName;
/** Filenames that were enumerated from the list directory operation*/
@property (nonatomic, retain) NSMutableArray *directoryContents;

@property (assign) NSTimeInterval timeOutSeconds;

#pragma mark init / dealloc

- (id)initWithURL:(NSURL *)ftpURL toDownloadFile:(NSString *)filePath;
- (id)initWithURL:(NSURL *)ftpURL toUploadFile:(NSString *)filePath;
- (id)initWithURL:(NSURL *)ftpURL toCreateDirectory:(NSString *)directoryName;
- (id)initWithURLToListDirectory:(NSURL *)ftpURL;

+ (id)requestWithURL:(NSURL *)ftpURL toDownloadFile:(NSString *)filePath;
+ (id)requestWithURL:(NSURL *)ftpURL toUploadFile:(NSString *)filePath;
+ (id)requestWithURL:(NSURL *)ftpURL toCreateDirectory:(NSString *)directoryName;
+ (id)requestWithURLToListDirectory:(NSURL *)ftpURL;

#pragma mark Request logic

- (void)cancelRequest;
- (void)startRequest;
- (void)startAsynchronous;


+ (NSOperationQueue *)sharedRequestQueue;

#pragma mark URL Fixer

@end

@interface NSString (SCRFTPRequest)

- (NSString *)scr_stringByFixingForURL;

@end
