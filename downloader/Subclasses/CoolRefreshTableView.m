//
//  CoolRefreshTableView.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/18/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "CoolRefreshTableView.h"

@implementation CoolRefreshTableView

- (void)reloadDataWithCoolAnimationType:(CoolRefreshAnimationStyle)style {
    
    [self reloadData];
    
    if (style == CoolRefreshAnimationStyleNone) {
        return;
    }
    
    CATransition *animation = [CATransition animation];
    [animation setType:kCATransitionPush];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [animation setFillMode:kCAFillModeBoth];
    [animation setDuration:.3];
    
    if (style == CoolRefreshAnimationStyleBackward) {
        [animation setSubtype:kCATransitionFromBottom];
    } else if (style == CoolRefreshAnimationStyleForward) {
        [animation setSubtype:kCATransitionFromTop];
    }
    
    [self.layer addAnimation:animation forKey:@"UITableViewReloadDataAnimationKey"];
}

@end
