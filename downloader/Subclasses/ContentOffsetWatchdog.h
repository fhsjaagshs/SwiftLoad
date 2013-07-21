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

@property (nonatomic, weak) id<ContentOffsetWatchdogDelegate> delegate;

- (void)resetOffset;

+ (id)watchdogWithScrollView:(UIScrollView *)scrollView;

@end

@protocol ContentOffsetWatchdogDelegate <NSObject>

@optional
- (void)watchdogWasTripped:(ContentOffsetWatchdog *)watchdog;
- (BOOL)shouldTripWatchdog:(ContentOffsetWatchdog *)watchdog;;

@end