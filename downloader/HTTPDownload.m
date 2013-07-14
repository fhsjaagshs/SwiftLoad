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
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) NSFileHandle *handle;
@property (nonatomic, strong) NSMutableData *buffer;

@end

@implementation HTTPDownload

+ (HTTPDownload *)downloadWithURL:(NSURL *)aURL {
    return [[[self class]alloc]initWithURL:aURL];
}

- (id)initWithURL:(NSURL *)aUrl {
    self = [super init];
    if (self) {
        self.url = aUrl;
        self.buffer = [NSMutableData data];
    }
    return self;
}

- (void)showFailure {
    [super showFailure];
    [[NSFileManager defaultManager]removeItemAtPath:_filePath error:nil];
}

- (void)showSuccess {
    [super showSuccess];
    NSString *targetPath = getNonConflictingFilePathForPath([kDocsDir stringByAppendingPathComponent:[self.fileName percentSanitize]]);
    [[NSFileManager defaultManager]moveItemAtPath:_filePath toPath:targetPath error:nil];
}

- (void)stop {
    [super stop];
    [_connection cancel];
    [_buffer setLength:0];
    [[NSFileManager defaultManager]removeItemAtPath:_filePath error:nil];
    self.downloadedBytes = 0;
    self.fileSize = 0;
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
    self.fileName = [response.URL.absoluteString lastPathComponent];
    self.filePath = getNonConflictingFilePathForPath([NSTemporaryDirectory() stringByAppendingPathComponent:[self.fileName percentSanitize]]);
    self.fileSize = [response expectedContentLength];
    [[NSFileManager defaultManager]createFileAtPath:_filePath contents:nil attributes:nil];
    self.handle = [NSFileHandle fileHandleForWritingAtPath:_filePath];
}

- (void)connection:(NSURLConnection *)theConnection didReceiveData:(NSData *)receivedData {
    self.downloadedBytes += receivedData.length;
    
    [_buffer appendData:receivedData];
    
    if (_buffer.length > 131072) { // 128 KB
        [_handle writeData:_buffer];
        [_buffer setLength:0];
        [_handle synchronizeFile];
    }
    
    [self.delegate setProgress:((_fileSize == -1)?1:((float)_downloadedBytes/(float)_fileSize))];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self showFailure];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)theConnection {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.fileName = [self.fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    if (_downloadedBytes > 0) {
        
        if (_buffer.length > 0) {
            [_handle writeData:_buffer];
            [_handle synchronizeFile];
        }
        
        [_buffer setLength:0];
        
        [self showSuccess];
    } else {
        [self showFailure];
    }
}


@end
