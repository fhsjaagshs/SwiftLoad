//
//  NetworkActivityController.h
//  Swift
//
//  Created by Nathaniel Symer on 8/3/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NetworkActivityController : NSObject

+ (NetworkActivityController *)sharedController;

- (void)show;
- (void)hideIfPossible;
- (void)incrementCount;

@end
