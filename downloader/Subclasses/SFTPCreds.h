//
//  SFTPCreds.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 7/6/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SFTPCreds : NSObject

+ (void)removeCredsForURL:(NSURL *)ftpurl;
+ (void)saveUsername:(NSString *)username andPassword:(NSString *)password forURL:(NSURL *)ftpurl;
+ (NSDictionary *)getCredsForURL:(NSURL *)ftpurl;

@end
