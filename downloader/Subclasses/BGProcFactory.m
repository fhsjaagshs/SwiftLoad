//
//  BGProcFactory.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/19/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "BGProcFactory.h"

@interface BGProcFactory ()

@property (nonatomic, retain) NSMutableDictionary *core;

@end

@implementation BGProcFactory

- (void)startProcForKey:(NSString *)key andExpirationHandler:(void(^)())block {
    __block UIBackgroundTaskIdentifier identifier = [[UIApplication sharedApplication]beginBackgroundTaskWithExpirationHandler:^{
        block();
        [self endProcForKey:key];
    }];
    
    _core[key] = [NSString stringWithFormat:@"%lu",(unsigned long)identifier];
}

- (void)endProcForKey:(NSString *)key {
    UIBackgroundTaskIdentifier identifier = [_core[key]unsignedIntValue];
    if (identifier != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication]endBackgroundTask:identifier];
        identifier = UIBackgroundTaskInvalid;
        if (_core[key]) {
            [_core removeObjectForKey:key];
        }
    }
}

- (void)endAllTasks {
    for (NSString *key in _core.allKeys) {
        UIBackgroundTaskIdentifier identifier = [_core[key]unsignedIntValue];
        if (identifier != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication]endBackgroundTask:identifier];
            identifier = UIBackgroundTaskInvalid;
        }
    }
    [_core removeAllObjects];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.core = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (BGProcFactory *)sharedFactory {
    static BGProcFactory *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[BGProcFactory alloc]init];
    });
    return shared;
}

@end
