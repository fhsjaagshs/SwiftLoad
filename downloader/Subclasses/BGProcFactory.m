//
//  BGProcFactory.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/19/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "BGProcFactory.h"

static BGProcFactory *sharedInstance = nil;

@interface BGProcFactory ()

@property (nonatomic, retain) NSMutableDictionary *core;

@end

@implementation BGProcFactory

- (void)startProcForKey:(NSString *)key andExpirationHandler:(void(^)())block {
    __block UIBackgroundTaskIdentifier identifier = [[UIApplication sharedApplication]beginBackgroundTaskWithExpirationHandler:^{
        block();
        if (_core[key]) {
            [_core removeObjectForKey:key];
        }
        [[UIApplication sharedApplication]endBackgroundTask:identifier];
        identifier = UIBackgroundTaskInvalid;
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
    NSMutableDictionary *corecopy = [[_core mutableCopy]autorelease];
    for (NSString *key in corecopy.allKeys) {
        [self endProcForKey:key];
    }
}

- (id)init {
    self = [super init];
    if (self) {
        self.core = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (BGProcFactory *)sharedFactory {
    @synchronized (self) {
        if (sharedInstance == nil) {
            [[self alloc]init];
        }
    }
    return sharedInstance;
}

// Override stuff to make sure that the singleton is never dealloc'd. Fun.
+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedInstance == nil) {
            sharedInstance = [super allocWithZone:zone];
            return sharedInstance;
        }
    }
    return nil;
}

- (id)retain {
    return self;
}

- (oneway void)release {
    // Do nothing
}

- (id)autorelease {
    return self;
}

- (NSUInteger)retainCount {
    return NSUIntegerMax;
}

- (void)dealloc {
    [self setCore:nil];
    [super dealloc];
}

@end
