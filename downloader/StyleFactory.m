//
//  Style.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/20/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "StyleFactory.h"

static StyleFactory *sharedInstance = nil;

@implementation StyleFactory

- (UIImageView *)backgroundImageView {
    UIImageView *background = [[[UIImageView alloc]initWithFrame:[UIApplication sharedApplication].delegate.window.bounds]autorelease];
    [background setImage:[UIImage imageNamed:@"background"]];
    return background;
}

+ (StyleFactory *)sharedFactory {
    @synchronized (self) {
        if (sharedInstance == nil) {
            [[self alloc]init];
        }
    }
    return sharedInstance;
}

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

@end
