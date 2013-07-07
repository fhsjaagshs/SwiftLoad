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
@property (nonatomic, retain) NSOutputStream *output;

@end

@implementation HTTPDownload

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
			NSLog(@"stream opened");
        } break;
        case NSStreamEventHasSpaceAvailable: {
            NSLog(@"space available");
        } break;
        case NSStreamEventEndEncountered: {
            NSLog(@"end encountered");
        } break;
        case NSStreamEventErrorOccurred: {
			NSLog(@"ERROR");
        } break;
        default: {
        } break;
    }
}

- (void)writeData {
    NSLog(@"Writing Started: %@ Thread",[NSThread isMainThread]?@"Main":@"Background");
    NSData *scndrybuff = [[_buffer copy]autorelease];
    [_buffer setLength:0];
    [_output write:scndrybuff.bytes maxLength:scndrybuff.length];
    NSLog(@"Writing Ended");
}

+ (HTTPDownload *)downloadWithURL:(NSURL *)aURL {
    return [[[[self class]alloc]initWithURL:aURL]autorelease];
}

- (id)initWithURL:(NSURL *)aUrl {
    self = [super init];
    if (self) {
        self.url = aUrl;
        self.buffer = [NSMutableData data];
    }
    return self;
}

- (void)stop {
    [super stop];
    [_connection cancel];
    [_output close];
    // remove temp file
    self.downloadedBytes = 0;
    self.fileSize = 0;
}

- (void)start {
    [super start];
    
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:_url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30.0];
    [theRequest setHTTPMethod:@"GET"];
    
    if ([NSURLConnection canHandleRequest:theRequest]) {
        self.connection = [[[NSURLConnection alloc]initWithRequest:theRequest delegate:self startImmediately:YES]autorelease];
    } else {
        [self showFailure];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
    self.fileName = [response.URL.absoluteString lastPathComponent];
    self.filePath = getNonConflictingFilePathForPath([kDocsDir stringByAppendingPathComponent:[self.fileName percentSanitize]]);
    self.fileSize = [response expectedContentLength];
    [[NSFileManager defaultManager]createFileAtPath:_filePath contents:nil attributes:nil];
    
    self.output = [NSOutputStream outputStreamToFileAtPath:_filePath append:NO];
    _output.delegate = self;
    [_output scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_output open];
    
    NSLog(@"%@",_output.streamError);
}

- (void)connection:(NSURLConnection *)theConnection didReceiveData:(NSData *)receivedData {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
        self.downloadedBytes += receivedData.length;
        
        NSLog(@"Buff Length: %lu, Downloaded %lu", (unsigned long)_buffer.length,(unsigned long)receivedData.length);
        
        if (_buffer.length > 65536 && _output.hasSpaceAvailable) { // 64KB
            [self writeData];
        } else {
            [_buffer appendData:receivedData];
        }
        
        [self.delegate setProgress:((_fileSize == -1)?1:((float)_downloadedBytes/(float)_fileSize))];
        [pool release];
    });
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self showFailure];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)theConnection {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.fileName = [self.fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    if (_downloadedBytes > 0) {
        
        if (_buffer.length > 0) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self writeData];
            });
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
    [self setOutput:nil];
    [self setBuffer:nil];
    [super dealloc];
}

@end
