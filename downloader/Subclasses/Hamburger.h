//
//  Hamburger.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 7/13/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HamburdgerViewDelegate;

@interface HamburgerButtonItem : UIBarButtonItem

- (void)setDelegate:(id<HamburdgerViewDelegate>)delegate;
+ (HamburgerButtonItem *)itemWithView:(UIView *)viewToMove;

@end

@protocol HamburdgerViewDelegate <NSObject>
@optional
- (void)hamburgerCellWasSelectedAtIndex:(int)index;

@end