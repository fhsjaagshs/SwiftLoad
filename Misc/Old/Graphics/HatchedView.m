//
//  HatchedView.m
//  Test
//
//  Created by Nathaniel Symer on 5/20/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "HatchedView.h"

@implementation HatchedView

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGColorRef firstColor = UIColorFromRGB(0.5f, 0.5f, 0.5f).CGColor;
    CGColorRef secondColor = UIColorFromRGB(0.55f, 0.55f, 0.55f).CGColor;
    CGContextSetFillColorWithColor(context, firstColor);
    CGContextFillRect(context, self.bounds);
    
    CGContextRestoreGState(context);
    CGContextSaveGState(context);
    
    CGFloat spacer = 20.0f;
    int rows = (self.bounds.size.width+self.bounds.size.height/spacer);
    CGFloat padding = 0.0f;
    CGMutablePathRef hatchPath = CGPathCreateMutable();
    for(int i = 1; i <= rows; i++) {
        CGPathMoveToPoint(hatchPath, nil, spacer*i, padding);
        CGPathAddLineToPoint(hatchPath, nil, padding, spacer*i);
    }
    CGContextAddPath(context, hatchPath);
    CGPathRelease(hatchPath);
    CGContextSetLineWidth(context, 7.0f);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetStrokeColorWithColor(context, secondColor);
    CGContextDrawPath(context, kCGPathStroke);
    CGContextRestoreGState(context);
}

@end
