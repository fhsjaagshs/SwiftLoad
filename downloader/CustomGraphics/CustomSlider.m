//
//  CustomSlider.m
//  SwiftLoad
//
//  Created by Nate Symer on 5/25/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "CustomSlider.h"
#import "Common.h"

@implementation CustomSlider

- (void)setupGraphics {
    [self setMinimumTrackTintColor:[UIColor colorWithPatternImage:[self maximumImage]]];
    [self setMaximumTrackTintColor:[UIColor colorWithPatternImage:[self minimumImage]]];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupGraphics];
    }
    return self;
}

- (UIImage *)minimumImage {
    UIGraphicsBeginImageContext(CGSizeMake(1, self.bounds.size.height));
    CGContextRef context = UIGraphicsGetCurrentContext();		
    UIGraphicsPushContext(context);

    CGColorRef shadowColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.5].CGColor;
    
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context, CGSizeMake(0, 2), 3.0, shadowColor);
    CGContextSetFillColorWithColor(context, DARK_BLUE);
    CGContextFillRect(context, self.bounds);
    CGContextRestoreGState(context);
    
    drawGlossAndGradient(context, self.bounds, LIGHT_BLUE, DARK_BLUE);
    
    UIGraphicsPopContext();								
    
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return outputImage;
}

- (UIImage *)maximumImage {
    UIGraphicsBeginImageContext(CGSizeMake(1, self.bounds.size.height));
    CGContextRef context = UIGraphicsGetCurrentContext();		
    UIGraphicsPushContext(context);	   

    CGColorRef shadowColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.5].CGColor;
    
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context, CGSizeMake(0, 2), 3.0, shadowColor);
    CGContextSetFillColorWithColor(context, LIGHT_BLUE);
    CGContextFillRect(context, self.bounds);
    CGContextRestoreGState(context);
    
    drawGlossAndGradient(context, self.bounds, DARK_BLUE, LIGHT_BLUE);
    
    UIGraphicsPopContext();								
    
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return outputImage;
}

- (void)awakeFromNib {
    [self setupGraphics];
}

@end
