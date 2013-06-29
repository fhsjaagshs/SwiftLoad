//
//  ShadowedTableView.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 2011/08/21.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//
//  Adapted from work done by Matt Gallagher.

#import "ShadowedTableView.h"

#define SHADOW_HEIGHT 20.0
#define SHADOW_INVERSE_HEIGHT 10.0

@implementation ShadowedTableView

- (CAGradientLayer *)shadowAsInverse:(BOOL)inverse {
	CAGradientLayer *newShadow = [[[CAGradientLayer alloc]init]autorelease];
	newShadow.frame = CGRectMake(0, 0, self.frame.size.width,inverse?SHADOW_INVERSE_HEIGHT:SHADOW_HEIGHT);
	CGColorRef darkColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:inverse?(SHADOW_INVERSE_HEIGHT/SHADOW_HEIGHT)*0.5:0.5].CGColor;
	CGColorRef lightColor = [self.backgroundColor colorWithAlphaComponent:0.0].CGColor;
	newShadow.colors = [NSArray arrayWithObjects:(id)(inverse?lightColor:darkColor), (id)(inverse?darkColor:lightColor), nil];
	return newShadow;
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
        [_bottomShadow setHidden:YES];
        [_topShadow setHidden:YES];
		return;
	}
	
	NSIndexPath *firstRow = [indexPathsForVisibleRows objectAtIndex:0];
	if (firstRow.section == 0 && firstRow.row == 0) {
		UIView *cell = [self cellForRowAtIndexPath:firstRow];
		if (!_topShadow) {
			self.topShadow = [self shadowAsInverse:YES];
			[cell.layer insertSublayer:_topShadow atIndex:0];
		} else if ([cell.layer.sublayers indexOfObjectIdenticalTo:_topShadow] != 0) {
			[cell.layer insertSublayer:_topShadow atIndex:0];
		}
        [_topShadow setHidden:NO];
		CGRect shadowFrame = _topShadow.frame;
		shadowFrame.size.width = cell.frame.size.width;
		shadowFrame.origin.y = -SHADOW_INVERSE_HEIGHT;
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

- (void)dealloc {
    [self setTopShadow:nil];
    [self setBottomShadow:nil];
	[super dealloc];
}

@end