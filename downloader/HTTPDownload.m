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

- (void)start {
    [super start];
    
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
    [[NSFileManager defaultManager]createFileAtPath:self.temporaryPath contents:nil attributes:nil];
    self.handle = [NSFileHandle fileHandleForWritingAtPath:self.temporaryPath];
    [_handle seekToEndOfFile];
}

- (void)connection:(NSURLConnection *)theConnection didReceiveData:(NSData *)receivedData {
    self.downloadedBytes += receivedData.length;
    [_handle seekToEndOfFile];
    [_handle writeData:receivedData];
    [_handle synchronizeFile];
    [self.delegate setProgress:((_fileSize == -1)?1:((float)_downloadedBytes/(float)_fileSize))];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [_connection cancel];
    [_handle closeFile];
    self.downloadedBytes = 0;
    self.fileSize = 0;
    [self showFailure];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)theConnection {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    [_handle closeFile];
    
    if (_downloadedBytes > 0) {
        [self showSuccess];
    } else {
        [self showFailure];
    }
}

@end
