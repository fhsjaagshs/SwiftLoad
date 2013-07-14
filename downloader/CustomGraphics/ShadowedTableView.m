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
@property (nonatomic, strong) CAGradientLayer *topShadow;
@property (nonatomic, strong) CAGradientLayer *bottomShadow;
@end

@implementation ShadowedTableView

- (CAGradientLayer *)shadowAsInverse:(BOOL)inverse {
	CAGradientLayer *newShadow = [[CAGradientLayer alloc]init];
	newShadow.frame = CGRectMake(0, 0, self.frame.size.width,inverse?10:20);
    UIColor *darkColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:inverse?0.25:0.5];
    UIColor *lightColor = [self.backgroundColor colorWithAlphaComponent:0.0];
    newShadow.colors = @[inverse?(__bridge id)lightColor.CGColor:(__bridge id)darkColor.CGColor, inverse?(__bridge id)darkColor.CGColor:(__bridge id)lightColor.CGColor];
	return newShadow;
}

- (void)setShadowsHidden:(BOOL)hidden {
    _topShadow.hidden = hidden;
    _bottomShadow.hidden = hidden;
}

- (void)layoutSubviews {
	[super layoutSubviews];
    
    if (!_topShadow) {
        self.topShadow = [self shadowAsInverse:YES];
    }
    
    if (!_bottomShadow) {
        self.bottomShadow = [self shadowAsInverse:NO];
    }
    
    NSArray *indexPathsForVisibleRows = [self indexPathsForVisibleRows];
    
    if (indexPathsForVisibleRows.count == 0) {
        [self setShadowsHidden:YES];
		return;
	}
	
	NSIndexPath *firstRow = [indexPathsForVisibleRows objectAtIndex:0];
	if (firstRow.section == 0 && firstRow.row == 0) {
		UIView *cell = [self cellForRowAtIndexPath:firstRow];
		if (!_topShadow) {
			self.topShadow = [self shadowAsInverse:YES];
			[cell.layer insertSublayer:_topShadow atIndex:cell.subviews.count-1];
		} else if ([cell.layer.sublayers indexOfObjectIdenticalTo:_topShadow] != 0) {
			[cell.layer insertSublayer:_topShadow atIndex:cell.subviews.count-1];
		}
        [_topShadow setHidden:NO];
		CGRect shadowFrame = _topShadow.frame;
		shadowFrame.size.width = cell.frame.size.width;
		shadowFrame.origin.y = -10;
		_topShadow.frame = shadowFrame;
	} else {
        [_topShadow setHidden:YES];
	}

	NSIndexPath *lastRow = [indexPathsForVisibleRows lastObject];
	if (lastRow.section == (self.numberOfSections-1) && lastRow.row == [self numberOfRowsInSection:lastRow.section]-1) {
		UIView *cell = [self cellForRowAtIndexPath:lastRow];
		if (!_bottomShadow) {
			self.bottomShadow = [self shadowAsInverse:NO];
			[cell.layer insertSublayer:_bottomShadow atIndex:0];
		} else if ([cell.layer.sublayers indexOfObjectIdenticalTo:_bottomShadow] != 0) {
            [cell.layer insertSublayer:_bottomShadow atIndex:0];
		}
        [_bottomShadow setHidden:NO];
		CGRect shadowFrame = _bottomShadow.frame;
		shadowFrame.size.width = cell.frame.size.width;
		shadowFrame.origin.y = cell.frame.size.height;
		_bottomShadow.frame = shadowFrame;
	} else {
        [_bottomShadow setHidden:YES];
	}
}


@end