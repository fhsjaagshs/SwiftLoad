//
//  HTTPDownload.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 7/4/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "HTTPDownload.h"

@interface HTTPDownload ()

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, assign) float downloadedBytes;
@property (nonatomic, assign) float fileSize;
@property (nonatomic, strong) NSFileHandle *handle;
@property (nonatomic, strong) NSMutableData *buffer;

@property (nonatomic, assign) BOOL isAppending;
@property (nonatomic, assign) float writtenBytes;

@end

@implementation HTTPDownload

+ (HTTPDownload *)downloadWithURL:(NSURL *)aURL {
    return [[[self class]alloc]initWithURL:aURL];
}

- (id)initWithURL:(NSURL *)aUrl {
    self = [super init];
    if (self) {
        self.url = aUrl;
        self.name = [_url.absoluteString.lastPathComponent percentSanitize];
        self.buffer = [NSMutableData data];
    }
    return self;
}

- (void)stop {
    [_connection cancel];
    [_buffer setLength:0];
    [_handle closeFile];
    self.downloadedBytes = 0;
    self.fileSize = 0;
    [super stop];
}

- (void)start {
    [super start];
    
    [_buffer setLength:0];
    
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:_url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30.0];
    [theRequest setHTTPMethod:@"GET"];

    if ([NSURLConnection canHandleRequest:theRequest]) {
        self.connection = [[NSURLConnection alloc]initWithRequest:theRequest delegate:self startImmediately:NO];
        [_connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        [_connection start];
    } else {
        [self showFailure];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
    self.name = (response.suggestedFilename.length > 0)?response.suggestedFilename:[[response.URL.absoluteString lastPathComponent]percentSanitize];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(setText:)]) {
        [self.delegate setText:self.name];
    }
    
    self.temporaryPath = getNonConflictingFilePathForPath([NSTemporaryDirectory() stringByAppendingPathComponent:[self.name percentSanitize]]);
    self.fileSize = [response expectedContentLength];
    NSLog(@"FileSize: %f",self.fileSize);
    [[NSFileManager defaultManager]createFileAtPath:self.temporaryPath contents:nil attributes:nil];
    self.handle = [NSFileHandle fileHandleForWritingAtPath:self.temporaryPath];
    
    __weak HTTPDownload *weakself = self;
    
    if (_fileSize != -1) {
        [_handle setWriteabilityHandler:^(NSFileHandle *handle) {
            if (!weakself.isAppending && weakself.buffer.length > 0) {
                NSData *data = [weakself.buffer copy];
                [weakself.buffer setLength:0];
                [handle seekToEndOfFile];
                [handle writeData:data];
                [handle synchronizeFile];
                weakself.writtenBytes += data.length;
                
                if (weakself.writtenBytes == weakself.fileSize) {
                    [handle closeFile];
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        @autoreleasepool {
                            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                            [weakself showSuccess];
                        }
                    });
                }
            }
        }];
    }
}

- (void)connection:(NSURLConnection *)theConnection didReceiveData:(NSData *)receivedData {
    self.downloadedBytes += receivedData.length;
    
    if (_fileSize == -1) {
        [_handle writeData:receivedData];
    } else {
        self.isAppending = YES;
        [_buffer appendData:receivedData];
        self.isAppending = NO;
    }

    [self.delegate setProgress:((_fileSize == -1)?1:((float)_downloadedBytes/(float)_fileSize))];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [_connection cancel];
    [_buffer setLength:0];
    [_handle closeFile];
    self.downloadedBytes = 0;
    self.fileSize = 0;
    [self showFailure];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)theConnection {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    if (_fileSize == -1) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [self showSuccess];
    }
    
    if (_downloadedBytes == 0) {
        [self showFailure];
    }
}

@end
