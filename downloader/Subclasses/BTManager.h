//
//  BTManager.h
//  Swift
//
//  Created by Nathaniel Symer on 9/30/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BTManager : NSObject

+ (BTManager *)shared;

- (BOOL)sendFileAtPath:(NSString *)path;

@property (nonatomic, copy) void(^sendingCompletionHandler)(NSError *error);
@property (nonatomic, copy) void(^receivingCompletionHandler)(NSError *error, NSString *path);

@end
