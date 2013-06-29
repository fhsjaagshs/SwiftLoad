//
//  CustomSegmentedControl.m
//  SwiftLoad
//
//  Created by Nate Symer on 5/22/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "CustomSegmentedControl.h"
#import "Common.h"

UIImage * getUIButtonImageNonPressedF(void);
UIImage * getUIButtonImagePressedF(void);
UIImage * getSeparatorImage(void);

@implementation CustomSegmentedControl

- (void)setupGraphics {
    [self setDividerImage:getSeparatorImage() forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    CGFloat height = self.frame.size.height;
    UIImage *button30 = [getUIButtonImageNonPressed(height) resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)];
    UIImage *button30q = [getUIButtonImagePressed(height) resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)];
    [self setBackgroundImage:button30 forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [self setBackgroundImage:button30q forState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
    [self addTarget:self action:@selector(segmentChanged) forControlEvents:UIControlEventValueChanged];
}

- (id)initWithItems:(NSArray *)items andFrame:(CGRect)frame {
    self = [super initWithItems:items];
    if (self) {
        [self setFrame:frame];
        [self setupGraphics];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupGraphics];
    }
    return self;
}

UIImage * getSeparatorImage(void) {
    CGFloat width = 2;
    CGFloat height = 44;
    
    UIGraphicsBeginImageContext(CGSizeMake(width, height));		
    CGContextRef context = UIGraphicsGetCurrentContext();		
    UIGraphicsPushContext(context);

    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextSetLineWidth(context, 1.5);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextStrokeRect(context, rectFor1PxStroke(CGRectMake(0, 0, width, height)));
    
    UIGraphicsPopContext();								
    
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    return outputImage;

}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self segmentChanged];
}

- (void)segmentChanged {
    for (UIView *view in self.subviews) {
        for (UIView *viewy in view.subviews) {
            if ([@"UISegmentLabel" isEqualToString:NSStringFromClass([viewy class])]) {
                if ([viewy respondsToSelector:@selector(setShadowColor:)]) {
                    [(UILabel *)viewy setShadowColor:[UIColor clearColor]];
                }
            }
        }
    }
}

- (void)awakeFromNib {
    [self setupGraphics];
}

@end
