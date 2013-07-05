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
@property (nonatomic, retain) NSMutableData *downloadedData;
@property (nonatomic, assign) float downloadedBytes;
@property (nonatomic, assign) float fileSize;

@end

@implementation HTTPDownload

+ (HTTPDownload *)downloadWithURL:(NSURL *)aURL {
    return [[[[self class]alloc]initWithURL:aURL]autorelease];
}

- (id)initWithURL:(NSURL *)aUrl {
    self = [super init];
    if (self) {
        self.url = aUrl;
        self.downloadedData = [NSMutableData data];
    }
    return self;
}

- (void)stop {
    [super stop];
    [_connection cancel];
    [_downloadedData setLength:0];
    self.downloadedBytes = 0;
    self.fileSize = 0;
}

- (void)start {
    [super start];
    
    NSMutableURLRequest *headReq = [NSMutableURLRequest requestWithURL:_url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:30.0];
    [headReq setHTTPMethod:@"HEAD"];
    
    [NSURLConnection sendAsynchronousRequest:headReq queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (!error) {
            NSDictionary *headers = [(NSHTTPURLResponse *)response allHeaderFields];
            if (headers) {
                if ([headers objectForKey:@"Content-Range"]) {
                    NSString *contentRange = [headers objectForKey:@"Content-Range"];
                    NSRange range = [contentRange rangeOfString:@"/"];
                    NSString *totalBytesCount = [contentRange substringFromIndex:range.location+1];
                    self.fileSize = [totalBytesCount floatValue];
                } else if ([headers objectForKey:@"Content-Length"]) {
                    self.fileSize = [[headers objectForKey:@"Content-Length"]floatValue];
                } else {
                    self.fileSize = -1;
                }
            }
            
            NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:_url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:30.0];
            [theRequest setHTTPMethod:@"GET"];
            
            if ([NSURLConnection canHandleRequest:theRequest]) {
                self.connection = [[[NSURLConnection alloc]initWithRequest:theRequest delegate:self]autorelease];
            } else {
                [self showFailure];
            }
            
        } else {
            self.complete = YES;
            self.succeeded = NO;
        }
    }];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
    self.fileName = [response.URL.absoluteString lastPathComponent];
}

- (void)connection:(NSURLConnection *)theConnection didReceiveData:(NSData *)recievedData {
    self.downloadedBytes += recievedData.length;
    [_downloadedData appendData:recievedData];
    [self.delegate setProgress:((_fileSize == -1)?1:_downloadedData.length/_fileSize)];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self showFailure];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)theConnection {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.fileName = [self.fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    if (_downloadedData.length > 0) {
        NSString *filePath = getNonConflictingFilePathForPath([kDocsDir stringByAppendingPathComponent:self.fileName]);
        [[NSFileManager defaultManager]createFileAtPath:filePath contents:_downloadedData attributes:nil];
        [self showSuccess];
    } else {
        [self showFailure];
    }
}

- (void)dealloc {
    [self setUrl:nil];
    [self setConnection:nil];
    [self setDownloadedData:nil];
    [super dealloc];
}

@end
