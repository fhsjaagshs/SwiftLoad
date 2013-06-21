//
//  DTCustomColoredAccessory.m
//  SwiftLoad
//
//  Created by Nate Symer on 4/27/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "DTCustomColoredAccessory.h"
#import <QuartzCore/QuartzCore.h>

void drawLinearGradientWithModifications(CGContextRef context, CGRect rect, CGColorRef startColor, CGColorRef endColor);

void drawLinearGradientWithModifications(CGContextRef context, CGRect rect, CGColorRef startColor, CGColorRef endColor) {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat locations[] = { 0.0, 1.0 };
    
    NSArray *colors = [NSArray arrayWithObjects:(id)startColor, (id)endColor, nil];
    
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (CFArrayRef)colors, locations);
    
    CGPoint startPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect)-5);
    CGPoint endPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
    
    CGContextSaveGState(context);
    CGContextAddRect(context, rect);
    CGContextSetShadowWithColor(context, CGSizeMake(1, 15), 1, [UIColor blackColor].CGColor);
    CGContextClip(context);
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    CGContextRestoreGState(context);
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
}

@implementation DTCustomColoredAccessory

@synthesize accessoryColor, highlightedColor;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

+ (DTCustomColoredAccessory *)accessoryWithColor:(UIColor *)color {
	DTCustomColoredAccessory *ret = [[[DTCustomColoredAccessory alloc]initWithFrame:CGRectMake(0, 0, 44.0, 44.0)]autorelease];
	ret.accessoryColor = color;
	return ret;
}

- (void)drawRect:(CGRect)rect {
    
    if (!self.accessoryColor) {
        self.accessoryColor = [UIColor blackColor];
    }
    
    if (!self.highlightedColor) {
        self.highlightedColor = [UIColor whiteColor];
    }

    CGRect b = CGRectMake(10, 10, 24, 24);;
    CGRect targetRect = CGRectMake(b.origin.x+1.5, b.origin.y+1.5, b.size.width-5, b.size.height-5);

    UIColor *mainGreenColor = [UIColor colorWithRed:105.0f/255.0f green:179.0f/255.0f blue:216.0f/255.0f alpha:1.0];
    UIColor *secondaryGreenColor = [UIColor colorWithRed:21.0/255.0 green:92.0/255.0 blue:136.0/255.0 alpha:1.0];
    
    CGContextRef ctxt = UIGraphicsGetCurrentContext();
    CGContextSetShadowWithColor(ctxt, CGSizeMake(self.bounds.size.width+2.5, self.bounds.size.height+2.5), 5, [UIColor blackColor].CGColor);
    
    // Draw Shadow's Circle
    CGContextSaveGState(ctxt);
    CGContextSetLineWidth(ctxt, 2.1);
    CGContextAddEllipseInRect(ctxt, targetRect);
    CGContextSetShadowWithColor(ctxt, CGSizeMake(0, 1.25), 1.5, [UIColor darkGrayColor].CGColor);
    CGContextDrawPath(ctxt, kCGPathStroke);
    
    if (self.highlighted) {
		[self.highlightedColor setStroke];
	} else {
		[self.accessoryColor setStroke];
	}
    
    CGContextStrokeEllipseInRect(ctxt, targetRect);
    CGContextRestoreGState(ctxt);
    
    // Draw Gradient
    CGContextSaveGState(ctxt);
    CGContextAddEllipseInRect(ctxt, targetRect);
    CGContextClip(ctxt);
    drawLinearGradientWithModifications(ctxt, targetRect, mainGreenColor.CGColor, secondaryGreenColor.CGColor);
    CGContextRestoreGState(ctxt);
    
    // Draw Circle
    CGContextSaveGState(ctxt);
    CGContextSetLineWidth(ctxt, 2.1);
    CGContextAddEllipseInRect(ctxt, targetRect);
    CGContextDrawPath(ctxt, kCGPathStroke);
    
    if (self.highlighted) {
		[self.highlightedColor setStroke];
	} else {
		[self.accessoryColor setStroke];
	}
    
    CGContextStrokeEllipseInRect(ctxt, targetRect);
    CGContextRestoreGState(ctxt);
    
    // Draw Arrow
	// (x,y) is the tip of the arrow
	CGFloat x = CGRectGetMidX(targetRect)+3;
	CGFloat y = CGRectGetMidY(targetRect);
	const CGFloat R = 4;
	
    CGContextSetShadowWithColor(ctxt, CGSizeMake(1, 1), 5, [UIColor darkGrayColor].CGColor);
    
	CGContextMoveToPoint(ctxt, x-R, y-R);
	CGContextAddLineToPoint(ctxt, x, y);
	CGContextAddLineToPoint(ctxt, x-R, y+R);
	CGContextSetLineCap(ctxt, kCGLineCapSquare);
	CGContextSetLineJoin(ctxt, kCGLineJoinMiter);
	CGContextSetLineWidth(ctxt, 2.9);
    
	if (self.highlighted) {
		[self.highlightedColor setStroke];
	} else {
		[self.accessoryColor setStroke];
	}
    
	CGContextStrokePath(ctxt);
}

- (void)setHighlighted:(BOOL)highlighted {
	[super setHighlighted:highlighted];
	[self setNeedsDisplay];
}

- (void)dealloc {
    [self setAccessoryColor:nil];
    [self setHighlightedColor:nil];
    [super dealloc];
}

@end
