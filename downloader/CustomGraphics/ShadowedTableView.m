//
//  ShadowedTableView.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 2011/08/21.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//
//  Adapted from work done by Matt Gallagher.

#import "ShadowedTableView.h"
#import <QuartzCore/QuartzCore.h>

@interface ShadowedTableView ()

@property (nonatomic, weak) UITableViewCell *topCell;
@property (nonatomic, weak) UITableViewCell *bottomCell;

@end

@implementation ShadowedTableView

- (void)clearTopShadow {
    _topCell.layer.shadowPath = nil;
    _topCell.layer.shadowOpacity = 0.0f;
    _topCell.layer.shouldRasterize = NO;
}

- (void)clearBottomShadow {
    _bottomCell.layer.shadowPath = nil;
    _bottomCell.layer.shadowOpacity = 0.0f;
    _bottomCell.layer.shouldRasterize = NO;
}

- (void)endUpdates {
    [self clearTopShadow];
    [self clearBottomShadow];
    [super endUpdates];
}

- (void)layoutSubviews {
    [self clearTopShadow];
    [self clearBottomShadow];
    [super layoutSubviews];
    
    NSArray *indexPathsForVisibleRows = [self indexPathsForVisibleRows];
    
    if (indexPathsForVisibleRows.count == 0) {
        self.topCell = nil;
        self.bottomCell = nil;
		return;
	}
    
	NSIndexPath *firstRow = [indexPathsForVisibleRows objectAtIndex:0];
	if (firstRow.section == 0 && firstRow.row == 0) {
        self.topCell = [self cellForRowAtIndexPath:firstRow];
        _topCell.layer.shadowPath = [UIBezierPath bezierPathWithRect:_topCell.bounds].CGPath;
        _topCell.layer.shadowColor = [UIColor blackColor].CGColor;
        _topCell.layer.shadowOpacity = 0.2f;
	}
    
	NSIndexPath *lastRow = [indexPathsForVisibleRows lastObject];
	if (lastRow.section == (self.numberOfSections-1) && lastRow.row == [self numberOfRowsInSection:lastRow.section]-1) {
		self.bottomCell = [self cellForRowAtIndexPath:lastRow];
        _bottomCell.layer.shadowPath = [UIBezierPath bezierPathWithRect:CGRectMake(0, 8, _bottomCell.bounds.size.width, 44)].CGPath;
        _bottomCell.layer.shadowColor = [UIColor blackColor].CGColor;
        _bottomCell.layer.shadowOpacity = 0.25f;
    }
}

@end