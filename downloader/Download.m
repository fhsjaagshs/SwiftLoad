//
//  Download.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/17/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "Download.h"
#import "DownloadingCell.h"

NSString * const kDownloadChanged = @"downloadDone";

@interface Download ()

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, retain) NSMutableData *downloadedData;
@property (nonatomic, assign) float downloadedBytes;

@end

@implementation Download

+ (Download *)downloadWithURL:(NSURL *)aURL {
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
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.complete = YES;
    self.succeeded = NO;
    [_connection cancel];
    [_downloadedData setLength:0];
    self.downloadedBytes = 0;
    self.fileName = nil;
    self.fileSize = 0;
}

- (void)start {
    [[NSNotificationCenter defaultCenter]postNotificationName:kDownloadChanged object:self];
    self.complete = NO;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
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
            
            
            __block UIBackgroundTaskIdentifier background_task = [[UIApplication sharedApplication]beginBackgroundTaskWithExpirationHandler:^{
                [_connection cancel];
                [_downloadedData setLength:0];
                
                [[UIApplication sharedApplication]endBackgroundTask:background_task];
                background_task = UIBackgroundTaskInvalid;
            }];
            
            NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:_url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:30.0];
            [theRequest setHTTPMethod:@"GET"];
            
            if ([NSURLConnection canHandleRequest:theRequest]) {
                self.connection = [[[NSURLConnection alloc]initWithRequest:theRequest delegate:self]autorelease];
            } else {
                [self showFailure];
            }
            
            [[UIApplication sharedApplication]endBackgroundTask:background_task];
            background_task = UIBackgroundTaskInvalid;
        } else {
            self.complete = YES;
            self.succeeded = NO;
        }
    }];
}

- (void)showFailure {
    [_delegate drawRed];
}

- (void)showSuccessForFilename:(NSString *)fileName {
    if (fileName.length > 14) {
        fileName = [[fileName substringToIndex:11]stringByAppendingString:@"..."];
    }
    
    UILocalNotification *notification = [[UILocalNotification alloc]init];
    notification.fireDate = [NSDate date];
    notification.alertBody = [NSString stringWithFormat:@"Finished downloading: %@",fileName];
    notification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication]presentLocalNotificationNow:notification];
    [notification release];
    
    [_delegate drawGreen];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
    self.fileName = [response.URL.absoluteString lastPathComponent];
}

- (void)connection:(NSURLConnection *)theConnection didReceiveData:(NSData *)recievedData {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    if (_downloadedData.length == 0) {
        self.downloadedData = [NSMutableData data];
    }
    
    self.downloadedBytes += recievedData.length;
    [_downloadedData appendData:recievedData];
    
    float progress = (_fileSize == -1)?1:_downloadedData.length/_fileSize;
    
    [_delegate setProgress:progress];
}

- (void)clearOutMyself {
    [_delegate reset];
    [[Downloads sharedDownloads]removeDownload:self];
    [[NSNotificationCenter defaultCenter]postNotificationName:kDownloadChanged object:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self showFailure];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)theConnection {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    NSString *filename = [_fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    self.complete = YES;
    
    if (_downloadedData.length > 0) {
        NSString *filePath = getNonConflictingFilePathForPath([kDocsDir stringByAppendingPathComponent:filename]);
        [[NSFileManager defaultManager]createFileAtPath:filePath contents:_downloadedData attributes:nil];
        [self showSuccessForFilename:filename];
        self.succeeded = YES;
    } else {
        self.succeeded = NO;
        [self showFailure];
    }
    [self performSelector:@selector(clearOutMyself) withObject:nil afterDelay:0.6f];
}

- (void)dealloc {
    [self setDelegate:nil];
    [self setFileName:nil];
    [self setUrl:nil];
    [self setConnection:nil];
    [self setDownloadedData:nil];
    [super dealloc];
}

@end
