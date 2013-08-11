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
    UIImageView *buttonBar = [[UIImageView alloc]initWithFrame:[UIScreen mainScreen].applicationFrame];
    [buttonBar setImage:[UIImage imageNamed:@"buttonbarBG"]];
    buttonBar.userInteractionEnabled = YES;
    return buttonBar;
}

@end
