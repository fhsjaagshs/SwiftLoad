//
//  HamburgerView.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 7/13/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HamburdgerViewDelegate;

@interface HamburgerView : UIView

+ (HamburgerView *)view;

@property (nonatomic, assign) id<HamburdgerViewDelegate> delegate;

@end

@protocol HamburdgerViewDelegate <NSObject>

- (void)hamburgerCellWasSelectedAtIndex:(int)index;

@end