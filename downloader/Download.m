//
//  Download.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/17/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "Download.h"

@interface Download ()

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, retain) NSMutableData *downloadedData;
@property (nonatomic, assign) float downloadedBytes;

@end

@implementation Download

- (void)downloadURL:(NSURL *)url {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    NSMutableURLRequest *headReq = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:30.0];
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
                    [[HUDProgressView progressViewWithTag:0]setIndeterminate:YES];
                }
            }
            
            
            __block UIBackgroundTaskIdentifier background_task = [[UIApplication sharedApplication]beginBackgroundTaskWithExpirationHandler:^{
                [self.connection cancel];
                [self.downloadedData setLength:0];
                
                [[UIApplication sharedApplication]endBackgroundTask:background_task];
                background_task = UIBackgroundTaskInvalid;
            }];
            
            NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:30.0];
            [theRequest setHTTPMethod:@"GET"];
            self.connection = [[[NSURLConnection alloc]initWithRequest:theRequest delegate:self]autorelease];
            
            [[UIApplication sharedApplication]endBackgroundTask:background_task];
            background_task = UIBackgroundTaskInvalid;
        }
    }];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
    self.fileName = [response.URL.absoluteString lastPathComponent];
}

- (void)connection:(NSURLConnection *)theConnection didReceiveData:(NSData *)recievedData {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    if (self.downloadedData.length == 0) {
        self.downloadedData = [NSMutableData data];
    }
    
    self.downloadedBytes += recievedData.length;
    [self.downloadedData appendData:recievedData];
    float progress = _downloadedData.length/_fileSize;
    [[HUDProgressView progressViewWithTag:0]setProgress:progress];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [[HUDProgressView progressViewWithTag:0]redrawRed];
    [[HUDProgressView progressViewWithTag:0]hideAfterDelay:1.5f];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)theConnection {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    NSString *filename = [_fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    if (self.downloadedData.length > 0) {
        NSString *filePath = getNonConflictingFilePathForPath([kDocsDir stringByAppendingPathComponent:filename]);
        [[NSFileManager defaultManager]createFileAtPath:filePath contents:self.downloadedData attributes:nil];
        [kAppDelegate showFinishedAlertForFilename:filename];
        [self.downloadedData setLength:0];
    } else {
        [[HUDProgressView progressViewWithTag:0]redrawRed];
        [[HUDProgressView progressViewWithTag:0]hideAfterDelay:1.5f];
    }
}


@end
