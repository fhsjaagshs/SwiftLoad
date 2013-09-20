//
//  SideSwipeCell.h
//  Swift
//
//  Created by Nathaniel Symer on 9/19/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "SwiftLoadCell.h"

@protocol SideSwipeCellDelegate;

@interface SideSwipeCell : SwiftLoadCell

@property (nonatomic, assign) BOOL swipeEnabled;
@property (nonatomic, strong) NSIndexPath *indexPath;

@property (nonatomic, weak) id<SideSwipeCellDelegate> delegate;

@end

@protocol SideSwipeCellDelegate <NSObject>

- (UIView *)viewForSideSwipeCell:(SideSwipeCell *)cell;

@end
