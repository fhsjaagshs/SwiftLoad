//
//  UIApplication+AppWindow.m
//  Swift
//
//  Created by Nathaniel Symer on 10/8/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "UIApplication+AppWindow.h"

@implementation UIApplication (AppWindow)

- (UIWindow *)appWindow {
    return ([[UIApplication sharedApplication]windows][0]);
}

@end
