//
//  Download.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/17/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "Download.h"
#import "DownloadingCell.h"

NSString * const kBackgroundTaskDownload = @"download";
float const kClearOutDelay = 0.6f;

@implementation Download

- (void)handleBackgroundTaskExpiration {
    
}

- (void)cancelBackgroundTask {
    [[BGProcFactory sharedFactory]endProcForKey:kBackgroundTaskDownload];
}

- (void)startBackgroundTask {
    [[BGProcFactory sharedFactory]startProcForKey:kBackgroundTaskDownload andExpirationHandler:^{
        [self stop];
        [self handleBackgroundTaskExpiration];
    }];
}

- (void)clearOutMyself {
    if (_delegate) {
        [_delegate reset];
    }
    [[DownloadController sharedController]removeDownload:self];
    [[DownloadController sharedController]downloadsChanged];
}

- (void)stop {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if ([[NSFileManager defaultManager]fileExistsAtPath:_temporaryPath]) {
        [[NSFileManager defaultManager]removeItemAtPath:_temporaryPath error:nil];
    }
    
   // [self clearOutMyself]; // Maybe?
    
    self.complete = YES;
    self.succeeded = NO;
    self.fileName = nil;
    [self cancelBackgroundTask];
}

- (void)start {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [[DownloadController sharedController]downloadsChanged];
    self.complete = NO;
    self.succeeded = NO;
    [self startBackgroundTask];
}

- (void)showFailure {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if ([[NSFileManager defaultManager]fileExistsAtPath:_temporaryPath]) {
        [[NSFileManager defaultManager]removeItemAtPath:_temporaryPath error:nil];
    }
    
    self.complete = YES;
    self.succeeded = NO;
    
    if (_delegate) {
        [_delegate drawRed];
    }
    
    [self performSelector:@selector(clearOutMyself) withObject:nil afterDelay:kClearOutDelay];
    [self cancelBackgroundTask];
}

- (void)showSuccess {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    NSString *targetPath = getNonConflictingFilePathForPath([kDocsDir stringByAppendingPathComponent:[_fileName percentSanitize]]);
    [[NSFileManager defaultManager]moveItemAtPath:_temporaryPath toPath:targetPath error:nil];
    
    fireNotification(_fileName);
    
    self.complete = YES;
    self.succeeded = YES;
    
    if (_delegate) {
        [_delegate drawGreen];
    }
    
    [self performSelector:@selector(clearOutMyself) withObject:nil afterDelay:kClearOutDelay];
    [self cancelBackgroundTask];
}

@end
