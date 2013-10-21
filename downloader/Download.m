//
//  Download.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/17/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "Download.h"

@implementation Download

- (void)stop {
    [[NetworkActivityController sharedController]hideIfPossible];
    
    if ([[NSFileManager defaultManager]fileExistsAtPath:_temporaryPath]) {
        [[NSFileManager defaultManager]removeItemAtPath:_temporaryPath error:nil];
    }
    [super stop];
}

- (NSString *)verb {
    return @"Downloading";
}

- (void)start {
    [[NetworkActivityController sharedController]show];
    [super start];
}

- (void)showFailure {
    [[NetworkActivityController sharedController]hideIfPossible];

    if ([[NSFileManager defaultManager]fileExistsAtPath:_temporaryPath]) {
        [[NSFileManager defaultManager]removeItemAtPath:_temporaryPath error:nil];
    }
    [super showFailure];
}

- (void)showSuccess {
    [[NetworkActivityController sharedController]hideIfPossible];

    NSString *targetPath = deconflictPath([kDocsDir stringByAppendingPathComponent:[self.name percentSanitize]]);
    [[NSFileManager defaultManager]moveItemAtPath:_temporaryPath toPath:targetPath error:nil];
    
    fireFinishDLNotification(self.name);
    [super showSuccess];
}

@end
