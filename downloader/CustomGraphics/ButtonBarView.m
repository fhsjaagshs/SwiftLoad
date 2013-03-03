//
//  ButtonBarView.m
//  SwiftLoad
//
//  Created by Nate Symer on 5/21/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "ButtonBarView.h"
#import "Common.h"

@implementation ButtonBarView

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGColorRef darkColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0].CGColor;
    CGColorRef lightColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0].CGColor;
    drawLinearGradient(context, rect, darkColor, lightColor);
    CGContextRestoreGState(context);
    CGContextSaveGState(context);
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextSetLineWidth(context, 4);
    CGContextStrokeRect(context, self.bounds);
    CGContextRestoreGState(context);
}

@end
