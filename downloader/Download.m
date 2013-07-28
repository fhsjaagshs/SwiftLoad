//
//  Download.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/17/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "Download.h"

float const kClearOutDelay = 0.6f;

@interface Download ()

@property (nonatomic, strong) NSString *bgTaskIdentifier;

@end

@implementation Download

- (instancetype)init {
    self = [super init];
    if (self) {
        self.bgTaskIdentifier = [NSString stringWithFormat:@"download-%u",arc4random()];
    }
    return self;
}

- (void)stop {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if ([[NSFileManager defaultManager]fileExistsAtPath:_temporaryPath]) {
        [[NSFileManager defaultManager]removeItemAtPath:_temporaryPath error:nil];
    }
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
