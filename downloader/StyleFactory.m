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
    UIImageView *buttonBar = [[[UIImageView alloc]initWithFrame:[UIApplication sharedApplication].delegate.window.bounds]autorelease];
    [buttonBar setImage:[UIImage imageNamed:@"buttonbarBG"]];
    return buttonBar;
}

+ (UIImageView *)backgroundImageView {
    UIImageView *background = [[[UIImageView alloc]initWithFrame:[UIApplication sharedApplication].delegate.window.bounds]autorelease];
    [background setImage:[UIImage imageNamed:@"Default"]];
    return background;
}

@end
