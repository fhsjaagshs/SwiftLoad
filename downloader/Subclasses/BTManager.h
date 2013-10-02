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

- (void)sendFileAtPath:(NSString *)path;
- (void)prepareForBackground;
- (void)prepareForForeground;

@property (nonatomic, assign) BOOL isTransferring;

@end
