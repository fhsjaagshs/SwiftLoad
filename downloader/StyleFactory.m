//
//  Style.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/20/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "StyleFactory.h"

@implementation StyleFactory

+ (UIImageView *)buttonBarImageView {
    UIImageView *buttonBar = [[[UIImageView alloc]initWithFrame:[UIScreen mainScreen].bounds]autorelease];
    [buttonBar setImage:[UIImage imageNamed:@"buttonbarBG"]];
    buttonBar.userInteractionEnabled = YES;
    return buttonBar;
}

+ (UIImageView *)backgroundImageView {
    UIImageView *background = [[[UIImageView alloc]initWithFrame:[UIScreen mainScreen].bounds]autorelease];
    [background setImage:[UIImage imageNamed:@"Default"]];
    background.userInteractionEnabled = YES;
    return background;
}

@end
