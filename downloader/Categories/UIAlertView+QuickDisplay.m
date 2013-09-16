//
//  UIAlertView+QuickDisplay.m
//  Swift
//
//  Created by Nathaniel Symer on 9/15/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "UIAlertView+QuickDisplay.h"

@implementation UIAlertView (QuickDisplay)

+ (void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message {
    [[[UIAlertView alloc]initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
}

@end
