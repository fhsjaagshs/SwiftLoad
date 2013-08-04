//
//  CircularProgressView.m
//  Swift
//
//  Created by Nathaniel Symer on 8/1/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "CircularProgressView.h"

@interface CircularProgressView ()

@property (nonatomic, assign) BOOL isFinished;
@property (nonatomic, assign) BOOL succeeded;

@end

@implementation CircularProgressView

- (void)reset {
    self.progress = 0.0f;
    self.isFinished = NO;
    [self setNeedsDisplay];
}

- (void)drawGreen {
    self.isFinished = YES;
    self.succeeded = YES;
    [self setNeedsDisplay];
}

- (void)drawRed {
    self.isFinished = YES;
    self.succeeded = NO;
    [self setNeedsDisplay];
}

- (void)setProgress:(float)progress {
	_progress = progress;
	[self setNeedsDisplay];
}

- (id)init {
	return [self initWithFrame:CGRectMake(0.0f, 0.0f, 37.0f, 37.0f)];
}

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		self.backgroundColor = [UIColor clearColor];
		self.opaque = NO;
		_progress = 0.0f;
	}
	return self;
}

- (void)drawRect:(CGRect)rect {
	CGRect allRect = self.bounds;
	CGRect circleRect = CGRectInset(allRect, 2.0f, 2.0f);
	CGContextRef context = UIGraphicsGetCurrentContext();
	
    float progress = _isFinished?1:_progress;
    
    UIColor *redColor = [UIColor colorWithRed:1.0f green:135.0f/255.0f blue:135.0f/255.0f alpha:1.0f];
    UIColor *greenColor = [UIColor colorWithRed:174.0f/255.0f green:242.0f/255.0f blue:187.0f/255.0f alpha:1.0f];
    
    UIColor *drawColor = (_isFinished?(_succeeded?greenColor:redColor):[UIColor darkGrayColor]);
    
    // Draw background
    
    CGContextSetStrokeColorWithColor(context, drawColor.CGColor);
    CGContextSetFillColorWithColor(context, [drawColor colorWithAlphaComponent:0.1f].CGColor);
    
    CGContextSetLineWidth(context, 2.0f);
    CGContextFillEllipseInRect(context, circleRect);
    CGContextStrokeEllipseInRect(context, circleRect);
    
    // Draw progress
    CGPoint center = CGPointMake(allRect.size.width / 2, allRect.size.height / 2);
    CGFloat radius = (allRect.size.width - 4) / 2;
    CGFloat startAngle = - ((float)M_PI / 2); // 90 degrees
    CGFloat endAngle = (progress * 2 * (float)M_PI) + startAngle;
    CGContextSetFillColorWithColor(context, drawColor.CGColor);
    CGContextMoveToPoint(context, center.x, center.y);
    CGContextAddArc(context, center.x, center.y, radius, startAngle, endAngle, 0);
    CGContextClosePath(context);
    CGContextFillPath(context);
}

@end
