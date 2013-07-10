//
//  UIButton+SwiftLoad.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 7/6/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "UIButton+SwiftLoad.h"

@implementation UIButton (SwiftLoad)

+ (UIButton *)customizedButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [button setBackgroundImage:[[UIImage imageNamed:@"button_icon"]resizableImageWithCapInsets:UIEdgeInsetsMake(4, 4, 4, 4)] forState:UIControlStateNormal];
    [button setBackgroundImage:[[UIImage imageNamed:@"button_icon_pressed"]resizableImageWithCapInsets:UIEdgeInsetsMake(4, 4, 4, 4)] forState:UIControlStateHighlighted];
    button.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    return button;
}

- (void)resizeForTitle {
    float width = [self.titleLabel.text sizeWithFont:self.titleLabel.font constrainedToSize:CGSizeMake(300, self.bounds.size.height)].width+10;
    self.frame = CGRectMake(((self.frame.size.width-width)/2)+self.frame.origin.x, self.frame.origin.y, width, self.frame.size.height);
}

@end
