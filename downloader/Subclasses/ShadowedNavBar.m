//
//  ShadowedNavBar.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/21/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "ShadowedNavBar.h"

@implementation ShadowedNavBar

- (void)willMoveToWindow:(UIWindow *)window {
    [super willMoveToWindow:window];
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(0.0, 4);
    self.layer.shadowOpacity = 0.25;
    self.layer.masksToBounds = NO;
    self.layer.shouldRasterize = YES;
    [self.superview bringSubviewToFront:self];
}

@end
