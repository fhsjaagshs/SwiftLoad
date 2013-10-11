//
//  UIApplication+Extension.h
//  Swift
//
//  Created by Nathaniel Symer on 10/8/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIApplication (Extensions)

- (UIWindow *)appWindow;

+ (NSString *)IPAddress;
+ (BOOL)isConnectedToWifi;
+ (BOOL)isConnectedToInternet;

@end
