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

@property (nonatomic, assign) BOOL isResuming;

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
    }
    return self;
}

- (void)stop {
    [_connection cancel];
    [_handle closeFile];
    self.downloadedBytes = 0;
    self.fileSize = 0;
    [super stop];
}

- (BOOL)canSelect {
    return self.complete;
}

- (NSString *)verb {
    if (self.complete && !self.succeeded) {
        return @"Tap to retry";
    }
    return [super verb];
}

- (void)resumeFromFailureIfNecessary {
    if (self.complete && !self.succeeded) {
        self.isResuming = YES;

        [self startBackgroundTask];
        
        [self.delegate reset];
        
        NSDictionary *attributes = [[NSFileManager defaultManager]attributesOfItemAtPath:self.temporaryPath error:nil];
        self.downloadedBytes = [attributes[NSFileSize] floatValue];
        
        [self.delegate setProgress:((_fileSize == -1)?1:(_downloadedBytes/_fileSize))];
        
        NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:_url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30.0f];
        [theRequest setHTTPMethod:@"GET"];
        [theRequest setValue:[NSString stringWithFormat:@"bytes=%f-",_downloadedBytes] forHTTPHeaderField:@"Range"];
        [theRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
        
        if ([NSURLConnection canHandleRequest:theRequest]) {
            self.connection = [[NSURLConnection alloc]initWithRequest:theRequest delegate:self startImmediately:NO];
            [_connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
            [_connection start];
        } else {
            [self showFailure];
        }
    }
}

- (void)start {
    [super start];
    
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:_url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30.0];
    [theRequest setHTTPMethod:@"GET"];
    [theRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];

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
    
    if (!_isResuming) {
        self.temporaryPath = getNonConflictingFilePathForPath([NSTemporaryDirectory() stringByAppendingPathComponent:[self.name percentSanitize]]);
        [[NSFileManager defaultManager]createFileAtPath:self.temporaryPath contents:nil attributes:nil];
    }
    
    self.fileSize = [response expectedContentLength];
    self.handle = [NSFileHandle fileHandleForWritingAtPath:self.temporaryPath];
    [_handle seekToEndOfFile];
}

- (void)connection:(NSURLConnection *)theConnection didReceiveData:(NSData *)receivedData {
    self.downloadedBytes += receivedData.length;
    [_handle seekToEndOfFile];
    [_handle writeData:receivedData];
    [_handle synchronizeFile];
    [self.delegate setProgress:((_fileSize == -1)?1:(_downloadedBytes/_fileSize))];
}

- (void)showFailure {
    [[NetworkActivityController sharedController]hideIfPossible];
    
    self.complete = YES;
    self.succeeded = NO;
    
    if (self.delegate) {
        [self.delegate drawRed];
    }
    
    [self cancelBackgroundTask];

    [_connection cancel];
    [_handle closeFile];
    [HamburgerView reloadCells];
}

- (void)showSuccess {
    [super showSuccess];
    [_handle closeFile];
    self.downloadedBytes = 0;
    self.fileSize = 0;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self showFailure];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)theConnection {
    if (_downloadedBytes > 0) {
        [self showSuccess];
    } else {
        [self showFailure];
    }
}

@end
