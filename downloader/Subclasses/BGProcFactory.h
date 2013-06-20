//
//  BGProcFactory.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/19/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BGProcFactory : NSObject

- (void)startProcForKey:(NSString *)key andExpirationHandler:(void(^)())block;
- (void)endProcForKey:(NSString *)key;
- (void)endAllTasks;

+ (BGProcFactory *)sharedFactory;

@end
