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
#define SHADOW_RATIO (SHADOW_INVERSE_HEIGHT / SHADOW_HEIGHT)

@implementation ShadowedTableView

@synthesize topShadow, bottomShadow;

- (void)removeTopShadow {
    if (self.topShadow.superlayer) {
        [self.topShadow removeFromSuperlayer];
    }
    [self setTopShadow:nil];
}

- (void)removeBottomShadow {
    if (self.bottomShadow.superlayer) {
        [self.bottomShadow removeFromSuperlayer];
    }
    [self setBottomShadow:nil];
}

- (CAGradientLayer *)shadowAsInverse:(BOOL)inverse {
	CAGradientLayer *newShadow = [[[CAGradientLayer alloc]init]autorelease];
	newShadow.frame = CGRectMake(0, 0, self.frame.size.width,inverse ? SHADOW_INVERSE_HEIGHT : SHADOW_HEIGHT);
	CGColorRef darkColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:inverse ? (SHADOW_INVERSE_HEIGHT / SHADOW_HEIGHT) * 0.5 : 0.5].CGColor;
	CGColorRef lightColor = [self.backgroundColor colorWithAlphaComponent:0.0].CGColor;
	newShadow.colors = [NSArray arrayWithObjects:(id)(inverse?lightColor:darkColor), (id)(inverse?darkColor:lightColor), nil];
	return newShadow;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	NSArray *indexPathsForVisibleRows = [self indexPathsForVisibleRows];
	if (indexPathsForVisibleRows.count == 0) {
        [self removeBottomShadow];
        [self removeTopShadow];
		return;
	}
	
	NSIndexPath *firstRow = [indexPathsForVisibleRows objectAtIndex:0];
	if (firstRow.section == 0 && firstRow.row == 0) {
		UIView *cell = [self cellForRowAtIndexPath:firstRow];
		if (!self.topShadow) {
			self.topShadow = [self shadowAsInverse:YES];
			[cell.layer insertSublayer:self.topShadow atIndex:0];
		} else if ([cell.layer.sublayers indexOfObjectIdenticalTo:self.topShadow] != 0) {
			[cell.layer insertSublayer:self.topShadow atIndex:0];
		}
		CGRect shadowFrame = self.topShadow.frame;
		shadowFrame.size.width = cell.frame.size.width;
		shadowFrame.origin.y = -SHADOW_INVERSE_HEIGHT;
		self.topShadow.frame = shadowFrame;
	} else {
        [self removeTopShadow];
	}

	NSIndexPath *lastRow = [indexPathsForVisibleRows lastObject];
	if ([lastRow section] == [self numberOfSections] - 1 && [lastRow row] == [self numberOfRowsInSection:[lastRow section]] - 1) {
		UIView *cell = [self cellForRowAtIndexPath:lastRow];
		if (!self.bottomShadow) {
			self.bottomShadow = [self shadowAsInverse:NO];
			[cell.layer insertSublayer:self.bottomShadow atIndex:0];
		} else if ([cell.layer.sublayers indexOfObjectIdenticalTo:self.bottomShadow] != 0) {
            [cell.layer insertSublayer:self.bottomShadow atIndex:0];
		}
		CGRect shadowFrame = self.bottomShadow.frame;
		shadowFrame.size.width = cell.frame.size.width;
		shadowFrame.origin.y = cell.frame.size.height;
		self.bottomShadow.frame = shadowFrame;
	} else {
        [self removeBottomShadow];
	}
}

- (void)dealloc {
    [self setTopShadow:nil];
    [self setBottomShadow:nil];
	[super dealloc];
}

@end