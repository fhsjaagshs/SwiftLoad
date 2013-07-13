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
    UIImageView *buttonBar = [[[UIImageView alloc]initWithFrame:[UIScreen mainScreen].applicationFrame]autorelease];
    [buttonBar setImage:[UIImage imageNamed:@"buttonbarBG"]];
    buttonBar.userInteractionEnabled = YES;
    return buttonBar;
}

+ (UIView *)backgroundView {
    UIImageView *background = [[[UIImageView alloc]initWithFrame:[UIScreen mainScreen].applicationFrame]autorelease];
    [background setImage:[[UIColor colorWithWhite:0.9f alpha:1.0f]imageWithSize:[UIScreen mainScreen].applicationFrame.size]];
    background.userInteractionEnabled = YES;
    return background;
}

@end
