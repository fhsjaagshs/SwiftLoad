//
//  lol.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 3/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "lol.h"
#import "downloaderAppDelegate.h"

@implementation lol

// use this as the third arg in UIApplicationMain (in nsstring form: @"lol")

- (void)sendEvent:(UIEvent *)event {
    [super sendEvent:event];
    /*if (event.type == UIEventTypeRemoteControl) {
        downloaderAppDelegate *appDelegate = (downloaderAppDelegate *)[[UIApplication sharedApplication]delegate];
        [appDelegate handleTheEvent:event];
    }*/
}

@end