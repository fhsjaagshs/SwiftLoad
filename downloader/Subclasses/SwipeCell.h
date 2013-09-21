//
//  SwipeCell.h
//  Swift
//
//  Created by Nathaniel Symer on 9/20/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "SwiftLoadCell.h"

@protocol SwipeCellDelegate;

@interface SwipeCell : SwiftLoadCell

@property (nonatomic, assign) BOOL swipeEnabled;
@property (nonatomic, weak) id<SwipeCellDelegate> delegate;

- (void)hideWithAnimation:(BOOL)shouldAnimate;

@end

@protocol SwipeCellDelegate <NSObject>

@required
- (UIView *)backgroundViewForSwipeCell:(SwipeCell *)cell;

@optional
- (void)swipeCellWillReveal:(SwipeCell *)cell;
- (void)swipeCellDidReveal:(SwipeCell *)cell;
- (void)swipeCellWillHide:(SwipeCell *)cell;

@end


