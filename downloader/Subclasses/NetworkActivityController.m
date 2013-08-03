//
//  NetworkActivityController.m
//  Swift
//
//  Created by Nathaniel Symer on 8/3/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "NetworkActivityController.h"

@interface NetworkActivityController ()

@property (nonatomic, assign) int numberOfUses;

@end

@implementation NetworkActivityController

+ (NetworkActivityController *)sharedController {
    static NetworkActivityController *controller = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        controller = [[NetworkActivityController alloc]init];
    });
    return controller;
}

- (void)show {
    self.numberOfUses += 1;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)hideIfPossible {
    self.numberOfUses -= 1;
    
    if (_numberOfUses == 0) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }
}

@end
