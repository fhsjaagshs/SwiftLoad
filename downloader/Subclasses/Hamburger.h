//
//  Hamburger.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 7/13/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const kHamburgerTaskUpdateNotification;
extern NSString * const kHamburgerNowPlayingUpdateNotification;

@protocol HamburgerViewDelegate;

@interface HamburgerView : UIView

+ (void)reloadCells;

@end

@interface HamburgerButtonItem : UIBarButtonItem

- (void)setDelegate:(id<HamburgerViewDelegate>)delegate;
+ (HamburgerButtonItem *)itemWithView:(UIView *)viewToMove;

@end

@protocol HamburgerViewDelegate <NSObject>
@optional
- (void)hamburgerCellWasSelectedAtIndex:(int)index;
- (void)taskAtIndex:(int)index;

@end