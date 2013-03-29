//
//  CustomNavBar.m
//  Test
//
//  Created by Nathaniel Symer on 5/20/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "CustomNavBar.h"
#import "Common.h"

@implementation CustomNavBar

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();    
    drawGlossAndGradient(context, self.bounds, LIGHT_BLUE, DARK_BLUE);  
    CGContextSetStrokeColorWithColor(context, DARK_BLUE);
    CGContextSetLineWidth(context, 1.0);    
    CGContextStrokeRect(context, rectFor1PxStroke(self.bounds)); 
}

- (void)willMoveToWindow:(UIWindow *)window {
    [super willMoveToWindow:window];
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(0.0, 3.25);
    self.layer.shadowOpacity = 0.25;
    self.layer.masksToBounds = NO;
    self.layer.shouldRasterize = YES;
    [self.superview bringSubviewToFront:self];
}

@end
