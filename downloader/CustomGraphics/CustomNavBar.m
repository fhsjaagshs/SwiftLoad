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

@end
