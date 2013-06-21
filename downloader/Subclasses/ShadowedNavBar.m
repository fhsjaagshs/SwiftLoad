//
//  ShadowedNavBar.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/21/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "ShadowedNavBar.h"

@implementation ShadowedNavBar

/*- (void)drawRect:(CGRect)rect {
    CGRect bounds = self.bounds;
    bounds.size.height += 50.0f; // I'm reserving enough room for the shadow
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:bounds byRoundingCorners:(UIRectCornerTopLeft | UIRectCornerTopRight) cornerRadii:CGSizeMake(7.0, 7.0)];
    UIBezierPath *clipPath = [UIBezierPath bezierPathWithRect:self.bounds];
    [clipPath appendPath:maskPath];
    clipPath.usesEvenOddFillRule = YES;
    
    CGContextSaveGState(UIGraphicsGetCurrentContext()); {
        [clipPath addClip];
        [[UIColor blackColor]setFill];
        [maskPath fill];
    } CGContextRestoreGState(UIGraphicsGetCurrentContext());
}
*/
- (void)willMoveToWindow:(UIWindow *)window {
    [super willMoveToWindow:window];
    self.backgroundColor = [UIColor blackColor];
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(0.0, 4);
    self.layer.shadowOpacity = 0.25;
    self.layer.masksToBounds = NO;
    self.layer.shouldRasterize = YES;
    [self.superview bringSubviewToFront:self];
    
    /*CGRect bounds = self.layer.bounds;
    bounds.size.height += 50.0f; // I'm reserving enough room for the shadow
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:bounds byRoundingCorners:(UIRectCornerTopLeft | UIRectCornerTopRight) cornerRadii:CGSizeMake(7.0, 7.0)];
    
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = bounds;
    maskLayer.path = maskPath.CGPath;
    
    [self.layer addSublayer:maskLayer];
    self.layer.mask = maskLayer;*/
}

@end
