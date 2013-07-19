//
//  FTPDowload.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 7/4/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "FTPDownload.h"

@interface FTPDownload () <NSStreamDelegate>

@property (nonatomic, strong) NSInputStream *readStream;
@property (nonatomic, strong) NSFileHandle *handle;

@property (nonatomic, assign) int bufferSize;
@property (nonatomic, assign) float fileSize;
@property (nonatomic, assign) float bytesRead;


@end

@implementation FTPDownload

+ (FTPDownload *)downloadWithURL:(NSURL *)aURL {
    return [[[self class]alloc]initWithURL:aURL];
}

- (id)initWithURL:(NSURL *)aUrl {
    self = [super init];
    if (self) {
        self.url = aUrl;
        self.bufferSize = 32768; // start with 32KB buffer, increase it if reads fill it
    }
    return self;
}

- (void)killReadStream {
    [_readStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    _readStream.delegate = nil;
    [_readStream close];
    self.readStream = nil;
}

- (void)stop {
    [super stop];
    [self killReadStream];
    [_handle closeFile];
}

- (void)start {
    [super start];
    
    if (_username.length == 0) {
        self.username = @"anonymous";
        self.password = @"";
    }
    
    [self downloadFileUsingFtp:_url withUsername:_username andPassword:_password];
}

- (void)handleDownloadEvent:(NSStreamEvent)eventCode {
    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            _fileSize = [[_readStream propertyForKey:(id)kCFStreamPropertyFTPResourceSize]integerValue];
        } break;
        case NSStreamEventHasBytesAvailable: {
            uint8_t buffer[_bufferSize];
            NSInteger bytesRead = [_readStream read:buffer maxLength:sizeof(buffer)];
            
            _bytesRead += bytesRead;
            
            if (bytesRead == -1) {
                [self showFailure];
                return;
            } else if (bytesRead == 0) {
                [_readStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
                _readStream.delegate = nil;
                [_readStream close];
                self.readStream = nil;
                [self showSuccess];
            } else {
                [_handle writeData:[NSData dataWithBytes:buffer length:sizeof(buffer)]];
            }
        } break;
        case NSStreamEventErrorOccurred: {
            CFStreamError err = CFReadStreamGetError((CFReadStreamRef)_readStream);
            
            if (err.domain == kCFStreamErrorDomainFTP) {
                // error out
            }
        } break;
        default: {
        } break;
    }
}


- (void)downloadFileUsingFTP:(NSURL *)url {
    
    self.fileName = url.absoluteString.lastPathComponent;
    
    CFReadStreamRef readStreamTemp = CFReadStreamCreateWithFTPURL(kCFAllocatorDefault, (__bridge CFURLRef)url);
    if (!readStreamTemp) {
        [self showFailure];
        return;
    }
    
    NSString *path = getNonConflictingFilePathForPath([[kDocsDir stringByAppendingPathComponent:self.fileName]percentSanitize]);
    [[NSFileManager defaultManager]createFileAtPath:path contents:nil attributes:nil];
    self.handle = [NSFileHandle fileHandleForWritingAtPath:path];
    
    self.readStream = (__bridge NSInputStream *)readStreamTemp;
    CFRelease(readStreamTemp);
    [_readStream setProperty:@"anonymous" forKey:(id)kCFStreamPropertyFTPUserName];
    [_readStream setProperty:@"" forKey:(id)kCFStreamPropertyFTPPassword];
    _readStream.delegate = self;
    [_readStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_readStream open];
}

- (void)downloadFileUsingFtp:(NSURL *)url withUsername:(NSString *)username andPassword:(NSString *)password {
    self.username = username;
    self.password = password;
    
    NSString *path = getNonConflictingFilePathForPath([[kDocsDir stringByAppendingPathComponent:url.absoluteString.lastPathComponent]percentSanitize]);
    
    if (![[NSFileManager defaultManager]fileExistsAtPath:path]) {
        [[NSFileManager defaultManager]createFileAtPath:path contents:nil attributes:nil];
    }
    
    self.request = [SCRFTPRequest requestWithURL:url toDownloadFile:path];
    _request.username = _username;
    _request.password = _password;
    _request.delegate = self;
    _request.didFinishSelector = @selector(downloadFinished:);
    _request.didFailSelector = @selector(downloadFailed:);
    _request.willStartSelector = @selector(downloadWillStart:);
    _request.bytesReadSelector = @selector(bytesRead:);
    [_request startAsynchronous];
}

- (void)bytesRead:(SCRFTPRequest *)request {
    NSLog(@"%llu",_request.bytesRead/_request.fileSize);
    [self.delegate setProgress:((float)_request.bytesWritten/(float)_request.fileSize)];
}

- (void)downloadFinished:(SCRFTPRequest *)request {
    fireNotification(_url.absoluteString.lastPathComponent.percentSanitize);
    [self showSuccess];
}

- (void)downloadFailed:(SCRFTPRequest *)request {
    if ([_request.error.localizedDescription isEqualToString:@"FTP error 530"]) {
        [TransparentAlert showAlertWithTitle:@"Insecure Authorization Required" andMessage:@"The server requires authentication, but FTP sends passwords in plain text. Try using SFTP instead."];
        /*FTPLoginController *controller = [[[FTPLoginController alloc]initWithCompletionHandler:^(NSString *username, NSString *password, NSString *url) {
            if ([username isEqualToString:@"cancel"]) {
                [[NSFileManager defaultManager]removeItemAtPath:[kDocsDir stringByAppendingPathComponent:[url lastPathComponent]] error:nil];
            } else {
                self.username = username;
                self.password = password;
                _request.username = _username;
                _request.password = _password;
                [_request startRequest];
            }
        }]autorelease];
        [controller setUrl:_url.absoluteString isPredefined:YES];
        [controller setType:FTPLoginControllerTypeDownload];
        [controller show];*/
    } else {
        NSLog(@"Request.error = %@",_request.error);
        [self showFailure];
    }
}

- (void)downloadWillStart:(SCRFTPRequest *)request {
    self.fileName = [[request.ftpURL.absoluteString lastPathComponent]stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}


@end
