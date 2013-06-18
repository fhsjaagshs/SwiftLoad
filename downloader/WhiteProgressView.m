//
//  WhiteProgressView.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/18/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "WhiteProgressView.h"

@interface WhiteProgressView ()

@property (nonatomic, assign) BOOL redrawGreen;
@property (nonatomic, assign) BOOL redrawRed;

@end

@implementation WhiteProgressView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawGreen {
    self.redrawGreen = YES;
    self.redrawRed = NO;
    [self setNeedsDisplay];
}

- (void)drawRed {
    self.redrawGreen = NO;
    self.redrawRed = YES;
    [self setNeedsDisplay];
}

- (void)setIsIndeterminate:(float)isIndeterminate {
    _isIndeterminate = isIndeterminate;
    [self setNeedsDisplay];
}

- (void)setProgress:(float)progress {
    _progress = progress;
    self.redrawRed = NO;
    self.redrawGreen = NO;
    self.isIndeterminate = NO;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    UIBezierPath *outsidePath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:10];
    CGRect smallerBounds = CGRectMake(5, 5, self.bounds.size.width-10, self.bounds.size.height-10);
    UIBezierPath *insidePath = [UIBezierPath bezierPathWithRoundedRect:smallerBounds cornerRadius:10];
    CGRect finalSmallBounds = CGRectMake(6.5, 6.5, self.bounds.size.width-13, self.bounds.size.height-13);
    UIBezierPath *smallestPath = [UIBezierPath bezierPathWithRoundedRect:finalSmallBounds cornerRadius:10];
    
    CGContextSaveGState(context);
    
    if (_redrawGreen) {
        UIColor *greenColor = [UIColor colorWithRed:174.0f/255.0f green:242.0f/255.0f blue:187.0f/255.0f alpha:1.0f];
        CGContextSetFillColorWithColor(context, greenColor.CGColor);
        CGContextSetStrokeColorWithColor(context, greenColor.CGColor);
    } else if (_redrawRed) {
        UIColor *redColor = [UIColor colorWithRed:1.0f green:135.0f/255.0f blue:135.0f/255.0f alpha:1.0f];
        CGContextSetFillColorWithColor(context, redColor.CGColor);
        CGContextSetStrokeColorWithColor(context, redColor.CGColor);
    } else {
        CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
        CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    }
    
    CGContextSetLineWidth(context, 3);
    CGContextAddPath(context, outsidePath.CGPath);
    CGContextClip(context);
    CGContextAddPath(context, insidePath.CGPath);
    CGContextStrokePath(context);
    CGContextAddPath(context, smallestPath.CGPath);
    CGContextClip(context);
    
    if (_redrawGreen) {
        float distance = (self.bounds.size.width-10+1.5);
        CGRect fillRect = CGRectMake(5, 5, distance, self.bounds.size.height-10);
        CGContextFillRect(context, fillRect);
    } else if (_redrawRed) {
        float distance = (self.bounds.size.width-10+1.5);
        CGRect fillRect = CGRectMake(5, 5, distance, self.bounds.size.height-10);
        CGContextFillRect(context, fillRect);
    } else {
        if (_isIndeterminate) {
            
            CGFloat spacer = 20.0f;
            int rows = (self.bounds.size.width+(self.bounds.size.height/spacer));
            CGMutablePathRef hatchPath = CGPathCreateMutable();
            
            for (int i = 1; i <= rows; i++) {
                CGPathMoveToPoint(hatchPath, nil, (spacer*i), 0.0f);
                CGPathAddLineToPoint(hatchPath, nil, 0.0f, spacer*i);
            }
            
            CGContextAddPath(context, hatchPath);
            CGPathRelease(hatchPath);
            
            CGContextSetLineWidth(context, 7);
            CGContextSetLineCap(context, kCGLineCapRound);
            CGContextDrawPath(context, kCGPathStroke);
        } else {
            float lineCompensation = 1.45;
            float distance = (self.bounds.size.width-10+lineCompensation)*_progress;
            CGRect fillRect = CGRectMake(5, 5, distance, self.bounds.size.height-10);
            
            CGContextFillRect(context, fillRect);
        }
    }
    
    CGContextRestoreGState(context);
}

@end
