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
    if (event.subtype == UIEventTypeTouches) {
        UITouch *touch = [[event touchesForWindow:[kAppDelegate window]]anyObject];
        if (touch.phase == UITouchPhaseEnded) {
            [[kAppDelegate viewController]setWatchdogCanGoYES];
        }
    }
    
    [super sendEvent:event];
}

@end
