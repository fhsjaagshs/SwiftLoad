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
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if ([[NSFileManager defaultManager]fileExistsAtPath:_temporaryPath]) {
        [[NSFileManager defaultManager]removeItemAtPath:_temporaryPath error:nil];
    }
    [super stop];
}

- (NSString *)verb {
    return @"Downloading";
}

- (void)start {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [super start];
}

- (void)showFailure {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if ([[NSFileManager defaultManager]fileExistsAtPath:_temporaryPath]) {
        [[NSFileManager defaultManager]removeItemAtPath:_temporaryPath error:nil];
    }
    [super showFailure];
}

- (void)showSuccess {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    NSString *targetPath = getNonConflictingFilePathForPath([kDocsDir stringByAppendingPathComponent:[self.name percentSanitize]]);
    [[NSFileManager defaultManager]moveItemAtPath:_temporaryPath toPath:targetPath error:nil];
    
    fireNotification(self.name);
    [super showSuccess];
}

@end
