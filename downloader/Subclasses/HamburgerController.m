//
//  HamburgerController.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 7/13/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "HamburgerController.h"

static HamburgerController *sharedInstance;

@implementation HamburgerController

+ (HamburgerController *)sharedController {
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
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [super dealloc];
}

@end
