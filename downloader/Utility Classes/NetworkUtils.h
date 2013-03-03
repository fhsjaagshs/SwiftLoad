//
//  NetworkUtils.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 10/29/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NetworkUtils : NSObject

+ (BOOL)isConnectedToWifi;
+ (BOOL)isConnectedToInternet;

+ (NSString *)getIPAddress;

@end
