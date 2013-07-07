//
//  HTTPDownload.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 7/4/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "HTTPDownload.h"

@interface HTTPDownload () <NSStreamDelegate>

@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSMutableData *buffer;
@property (nonatomic, assign) float downloadedBytes;
@property (nonatomic, assign) float fileSize;
@property (nonatomic, retain) NSString *filePath;
@property (nonatomic, retain) NSFileHandle *fileHandle;

@end

@implementation HTTPDownload

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    switch (eventCode) {
        case NSStreamEventHasSpaceAvailable:
            // write
            break;
        case NSStreamEventErrorOccurred:
            
            break;
        default:
            break;
    }
}

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

- (void)stop {
    [super stop];
    [_connection cancel];
    self.downloadedBytes = 0;
    self.fileSize = 0;
}

- (void)start {
    [super start];
    
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:_url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:30.0];
    [theRequest setHTTPMethod:@"GET"];
    
    if ([NSURLConnection canHandleRequest:theRequest]) {
        self.connection = [[[NSURLConnection alloc]initWithRequest:theRequest delegate:self]autorelease];
    } else {
        [self showFailure];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
    self.fileName = [response.URL.absoluteString lastPathComponent];
    self.filePath = getNonConflictingFilePathForPath([kDocsDir stringByAppendingPathComponent:[self.fileName percentSanitize]]);
    self.fileSize = [response expectedContentLength];
    [[NSFileManager defaultManager]createFileAtPath:self.filePath contents:nil attributes:nil];
    self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:_filePath];
    
    if (!_fileHandle) {
        [self stop];
        [self showFailure];
        NSLog(@"Oops");
    }
}

- (void)connection:(NSURLConnection *)theConnection didReceiveData:(NSData *)receivedData {
    self.downloadedBytes += receivedData.length;
    
    NSLog(@"Length %lu",(unsigned long)receivedData.length);
    
    if (_buffer.length < 268435456) { // 256KB
        [_buffer appendData:receivedData];
    } else {
        NSLog(@"Writing");
        [_fileHandle writeData:_buffer];
        NSLog(@"Done writing");
        [_buffer setLength:0];
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
            [_fileHandle writeData:_buffer];
            [_buffer setLength:0];
        }
        
        [self showSuccess];
    } else {
        [self showFailure];
    }
}

- (void)dealloc {
    [self setFilePath:nil];
    [self setUrl:nil];
    [self setConnection:nil];
    [self setFileHandle:nil];
    [self setBuffer:nil];
    [super dealloc];
}

@end
