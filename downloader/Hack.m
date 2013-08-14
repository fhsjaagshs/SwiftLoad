//
//  Hack.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/18/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "Hack.h"

@implementation Hack

- (void)sendEvent:(UIEvent *)event {
    if (_shouldWatchTouches) {
        if (event.subtype == UIEventTypeTouches) {
            UITouch *touch = [[event touchesForWindow:self.keyWindow]anyObject];
            if (touch.phase == UITouchPhaseEnded) {
                ((MyFilesViewController *)[kAppDelegate viewController]).watchdogCanGo = YES;
            }
        }
    }
    [super sendEvent:event];
}

@end
