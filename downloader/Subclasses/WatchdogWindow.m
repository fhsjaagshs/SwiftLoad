//
//  WatchdogWindow.m
//  Swift
//
//  Created by Nathaniel Symer on 8/13/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "WatchdogWindow.h"

@implementation WatchdogWindow

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    NSLog(@"touches ended in the watchdog window");
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    
}

@end
