//
//  BackAndForwardButton.m
//  SwiftLoad
//
//  Created by Nate Symer on 5/23/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "BackAndForwardButton.h"
#import "Common.h"

@implementation BackAndForwardButton

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();									

    CGColorRef lightColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0].CGColor;
    CGColorRef darkColor = [UIColor darkGrayColor].CGColor;
    
    CGRect _coloredBoxRect = CGRectMake(0, 0, rect.size.width, rect.size.height);
    
    drawGlossAndGradient(context, _coloredBoxRect, lightColor, darkColor);  
    CGContextSaveGState(context);
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextSetLineWidth(context, 1.5);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextStrokeRect(context, rectFor1PxStroke(_coloredBoxRect));
    CGContextRestoreGState(context);
}


@end
