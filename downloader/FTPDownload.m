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
@property (nonatomic, assign) int bufferSize;
@property (nonatomic, assign) float fileSize;
@property (nonatomic, assign) float bytesRead;

@property (nonatomic, strong) NSFileHandle *handle;
@property (nonatomic, strong) NSMutableData *tempBuffer;
@property (nonatomic, assign) BOOL isAppending;
@property (nonatomic, assign) float writtenBytes;

@end

@implementation FTPDownload

+ (FTPDownload *)downloadWithURL:(NSURL *)aURL {
    return [[[self class]alloc]initWithURL:aURL];
}

- (id)initWithURL:(NSURL *)aUrl {
    self = [super init];
    if (self) {
        self.url = aUrl;
        self.bufferSize = (1024*1024); // start with 1MB buffer, increase it if reads fill it, decrease it if reads don't fill it
        self.tempBuffer = [NSMutableData data];
    }
    return self;
}

- (void)stop {
    [self killReadStream];
    [_handle closeFile];
    [super stop];
}

- (void)start {
    [super start];
    [self downloadFileUsingFTP:_url];
}

- (void)handleDownloadEvent:(NSStreamEvent)eventCode {
    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            _fileSize = [[_readStream propertyForKey:(id)kCFStreamPropertyFTPResourceSize]integerValue];
        } break;
        case NSStreamEventHasBytesAvailable: {
            uint8_t buffer[_bufferSize];
            NSInteger bytesRead = [_readStream read:buffer maxLength:sizeof(buffer)];
            
            if (bytesRead/_bufferSize > 0.8) {
                _bufferSize *= 2;
            } else if (bytesRead/_bufferSize < 0.4) {
                _bufferSize /= 2;
            }
            
            _bytesRead += bytesRead;
            
            if (bytesRead == -1) {
                [_handle closeFile];
                [self showFailure];
                return;
            } else if (bytesRead == 0) {
                [self killReadStream];
            } else {
                self.isAppending = YES;
                [_tempBuffer appendBytes:buffer length:bytesRead];
                self.isAppending = NO;
            }
        } break;
        case NSStreamEventErrorOccurred: {
            CFStreamError err = CFReadStreamGetError((CFReadStreamRef)_readStream);
            
            if (err.domain == kCFStreamErrorDomainFTP) {
                [self showFailure];
            }
        } break;
        default: {
        } break;
    }
}

- (void)killReadStream {
    [_readStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    _readStream.delegate = nil;
    [_readStream close];
    self.readStream = nil;
}

- (void)downloadFileUsingFTP:(NSURL *)url {
    
    self.name = url.absoluteString.lastPathComponent;
    
    CFReadStreamRef readStreamTemp = CFReadStreamCreateWithFTPURL(kCFAllocatorDefault, (__bridge CFURLRef)url);
    if (!readStreamTemp) {
        [self showFailure];
        return;
    }
    
    self.temporaryPath = deconflictPath([[NSTemporaryDirectory() stringByAppendingPathComponent:self.name]percentSanitize]);
    [[NSFileManager defaultManager]createFileAtPath:self.temporaryPath contents:nil attributes:nil];
    self.handle = [NSFileHandle fileHandleForWritingAtPath:self.temporaryPath];
    
    __weak FTPDownload *weakself = self;
    
    [_handle setWriteabilityHandler:^(NSFileHandle *handle) {
        if (!weakself.isAppending && weakself.tempBuffer.length > 0) {
            NSData *data = weakself.tempBuffer;
            [weakself.tempBuffer setLength:0];
            [handle writeData:data];
            [handle synchronizeFile];
            weakself.writtenBytes += data.length;
            
            if (weakself.writtenBytes == weakself.fileSize) {
                [handle closeFile];
                dispatch_sync(dispatch_get_main_queue(), ^{
                    @autoreleasepool {
                        [weakself showSuccess];
                    }
                });
            }
        }
    }];
    
    self.readStream = (__bridge NSInputStream *)readStreamTemp;
    CFRelease(readStreamTemp);
    [_readStream setProperty:@"anonymous" forKey:(id)kCFStreamPropertyFTPUserName];
    [_readStream setProperty:@"" forKey:(id)kCFStreamPropertyFTPPassword];
    _readStream.delegate = self;
    [_readStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_readStream open];
}

@end
