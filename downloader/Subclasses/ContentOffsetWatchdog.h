//
//  ContentOffsetThingy.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/18/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "ShadowedTableView.h"

@protocol ContentOffsetWatchdogDelegate;

@interface ContentOffsetWatchdog : UIView

@property (nonatomic, assign) id<ContentOffsetWatchdogDelegate> delegate;

- (id)initWithScrollView:(UIScrollView *)scrollView;
+ (id)watchdogWithScrollView:(UIScrollView *)scrollView;

@end

@protocol ContentOffsetWatchdogDelegate <NSObject>

@optional
- (void)watchdogWasTripped;
- (BOOL)shouldTripWatchdog;

@end