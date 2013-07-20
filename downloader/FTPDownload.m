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
        self.bufferSize = (1024*1024); // start with 1MB buffer, increase it if reads fill it
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
                [self showFailure];
                return;
            } else if (bytesRead == 0) {
                [self killReadStream];
                [self showSuccess];
            } else {
                [_handle writeData:[NSData dataWithBytes:buffer length:bytesRead]];
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

@end
