//
//  CustomTextField.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 3/3/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "CustomTextField.h"

@implementation CustomTextField

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(context);
    
    CGColorRef lightColor = [UIColor whiteColor].CGColor;
    CGColorRef darkColor = [UIColor colorWithWhite:0.75f alpha:1.0f].CGColor;
    
    CGRect _coloredBoxRect = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    
    // Draw gloss and gradient
    drawGlossAndGradient(context, _coloredBoxRect, lightColor, darkColor);
    
    // Draw stroke
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextSetLineWidth(context, 1.5);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextStrokeRect(context, rectFor1PxStroke(_coloredBoxRect));
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self setNeedsDisplay];
}

@end
