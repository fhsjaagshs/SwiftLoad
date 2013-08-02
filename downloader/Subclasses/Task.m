//
//  Task.m
//  Swift
//
//  Created by Nathaniel Symer on 7/28/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "Task.h"

float const kClearOutDelayTask = 0.6f;

@interface Task ()

@property (nonatomic, strong) NSString *bgTaskIdentifer;

@end

@implementation Task

- (id)init {
    self = [super init];
    if (self) {
        self.bgTaskIdentifer = [NSString stringWithFormat:@"task-%u",arc4random()];
    }
    return self;
}

- (BOOL)canStop {
    return YES;
}

- (void)handleBackgroundTaskExpiration {
    
}

- (NSString *)verb {
    return @"";
}

- (void)cancelBackgroundTask {
    [[BGProcFactory sharedFactory]endProcForKey:_bgTaskIdentifer];
}

- (void)startBackgroundTask {
    [[BGProcFactory sharedFactory]startProcForKey:_bgTaskIdentifer andExpirationHandler:^{
        [self stop];
        [self handleBackgroundTaskExpiration];
    }];
}

- (void)clearOutMyself {
    if (_delegate) {
        [_delegate reset];
    }
    [[TaskController sharedController]removeTask:self];
    [[NSNotificationCenter defaultCenter]postNotificationName:kHamburgerTaskUpdateNotification object:nil];
}

- (void)stop {
    self.complete = YES;
    self.succeeded = NO;
    [self cancelBackgroundTask];
    [self performSelector:@selector(clearOutMyself) withObject:nil afterDelay:kClearOutDelayTask];
}

- (void)start {
    self.complete = NO;
    self.succeeded = NO;
    [self startBackgroundTask];
    [[NSNotificationCenter defaultCenter]postNotificationName:kHamburgerTaskUpdateNotification object:nil];
}

- (void)showFailure {

    self.complete = YES;
    self.succeeded = NO;
    
    if (_delegate && [_delegate respondsToSelector:@selector(drawRed)]) {
        [_delegate drawRed];
    }
    
    [self performSelector:@selector(clearOutMyself) withObject:nil afterDelay:kClearOutDelayTask];
    [self cancelBackgroundTask];
}

- (void)showSuccess {
    self.complete = YES;
    self.succeeded = YES;
    
    if (_delegate && [_delegate respondsToSelector:@selector(drawGreen)]) {
        [_delegate drawGreen];
    }
    
    [self performSelector:@selector(clearOutMyself) withObject:nil afterDelay:kClearOutDelayTask];
    [self cancelBackgroundTask];
}

@end
