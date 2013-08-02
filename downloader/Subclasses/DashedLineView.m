//
//  DashedLineView.m
//  Swift
//
//  Created by Nathaniel Symer on 8/1/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "DashedLineView.h"

@implementation DashedLineView


- (instancetype)init {
    self = [super init];
    if (self) {
        self.layer.rasterizationScale = [[UIScreen mainScreen]scale];
        self.layer.shouldRasterize = YES;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    CGFloat dashes[] = {5,5};
    
    CGContextSetFillColorWithColor(context, [[kAppDelegate window]backgroundColor].CGColor);
    CGContextFillRect(context, self.bounds);
    
    CGContextSetStrokeColorWithColor(context, [UIColor darkGrayColor].CGColor);
    
    CGContextSetLineWidth(context, self.bounds.size.height/4);
    CGContextSetLineDash(context, 0.0f, dashes, 2);
    
    
    CGContextMoveToPoint(context, 20, self.bounds.size.height/2);
    CGContextAddLineToPoint(context, self.bounds.size.width-20, self.bounds.size.height/2);
    
    CGContextStrokePath(context);
    
    CGContextRestoreGState(context);
}

@end
