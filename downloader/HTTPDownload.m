//
//  HTTPDownload.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 7/4/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "HTTPDownload.h"

@interface HTTPDownload ()

@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, assign) float downloadedBytes;
@property (nonatomic, assign) float fileSize;
@property (nonatomic, retain) NSString *filePath;

@end

@implementation HTTPDownload

+ (HTTPDownload *)downloadWithURL:(NSURL *)aURL {
    return [[[[self class]alloc]initWithURL:aURL]autorelease];
}

- (id)initWithURL:(NSURL *)aUrl {
    self = [super init];
    if (self) {
        self.url = aUrl;
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
    // remove temp file
    self.downloadedBytes = 0;
    self.fileSize = 0;
}

- (void)start {
    [super start];
    
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:_url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30.0];
    [theRequest setHTTPMethod:@"GET"];

    if ([NSURLConnection canHandleRequest:theRequest]) {
        self.connection = [[[NSURLConnection alloc]initWithRequest:theRequest delegate:self startImmediately:NO]autorelease];
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
}

- (void)connection:(NSURLConnection *)theConnection didReceiveData:(NSData *)receivedData {
    self.downloadedBytes += receivedData.length;
    [receivedData writeToFile:_filePath atomically:NO];
    [self.delegate setProgress:((_fileSize == -1)?1:((float)_downloadedBytes/(float)_fileSize))];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self showFailure];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)theConnection {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.fileName = [self.fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    if (_downloadedBytes > 0) {
        [self showSuccess];
    } else {
        [self showFailure];
    }
}

- (void)dealloc {
    [self setFilePath:nil];
    [self setUrl:nil];
    [self setConnection:nil];
    [super dealloc];
}

@end
