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
NSString * const kBackgroundTaskDownload = @"download";

@implementation Download

- (void)handleBackgroundTaskExpiration {
    [self stop];
}

- (void)cancelBackgroundTask {
    [[BGProcFactory sharedFactory]endProcForKey:kBackgroundTaskDownload];
}

- (void)startBackgroundTask {
    [[BGProcFactory sharedFactory]startProcForKey:kBackgroundTaskDownload andExpirationHandler:^{
        [self handleBackgroundTaskExpiration];
    }];
}

- (void)clearOutMyself {
    [_delegate reset];
    [[Downloads sharedDownloads]removeDownload:self];
    [[NSNotificationCenter defaultCenter]postNotificationName:kDownloadChanged object:self];
}

- (void)stop {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.complete = YES;
    self.succeeded = NO;
    self.fileName = nil;
    [self cancelBackgroundTask];
}

- (void)start {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [[NSNotificationCenter defaultCenter]postNotificationName:kDownloadChanged object:self];
    self.complete = NO;
    self.succeeded = NO;
    [self startBackgroundTask];
}

- (void)showFailure {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.complete = YES;
    self.succeeded = NO;
    [_delegate drawRed];
    [self performSelector:@selector(clearOutMyself) withObject:nil afterDelay:0.6f];
    [self cancelBackgroundTask];
}

- (void)showSuccess {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if (_fileName.length > 14) {
        self.fileName = [[_fileName substringToIndex:11]stringByAppendingString:@"..."];
    }
    
    UILocalNotification *notification = [[UILocalNotification alloc]init];
    notification.fireDate = [NSDate date];
    notification.alertBody = [NSString stringWithFormat:@"Finished downloading: %@",_fileName];
    notification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication]presentLocalNotificationNow:notification];
    [notification release];
    
    self.complete = YES;
    self.succeeded = YES;
    
    [_delegate drawGreen];
    [self performSelector:@selector(clearOutMyself) withObject:nil afterDelay:0.6f];
    [self cancelBackgroundTask];
}

- (void)dealloc {
    [self setDelegate:nil];
    [self setFileName:nil];
    [super dealloc];
}

@end
