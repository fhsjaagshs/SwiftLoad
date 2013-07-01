//
//  CustomButton.m
//  SwiftLoad
//
//  Created by Nate Symer on 5/21/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "CustomButton.h"
#import "Common.h"

@implementation CustomButton

- (void)setBGImage {
    CGFloat height = self.frame.size.height;
    UIImage *buttonImage = [getUIButtonImageNonPressed(height) resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)];
    [self setBackgroundImage:buttonImage forState:UIControlStateNormal];
    
    UIImage *buttonImagePressed = [getUIButtonImagePressed(height) resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)];
    [self setBackgroundImage:buttonImagePressed forState:UIControlStateHighlighted];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setBGImage];
        self.titleLabel.textColor = [UIColor whiteColor];
        self.titleLabel.shadowColor = [UIColor darkGrayColor];
        self.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self setBGImage];
}

- (void)awakeFromNib {
    [self setBGImage];
}

@end
