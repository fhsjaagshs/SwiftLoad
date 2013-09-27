//
//  UITableView+CoolRefresh.m
//  Swift
//
//  Created by Nathaniel Symer on 7/20/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "UITableView+CoolRefresh.h"
#import <objc/runtime.h>

CoolRefreshAnimationStyle animationStyle;

@implementation UITableView (CoolRefresh)

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if (animationStyle == CoolRefreshAnimationStyleBackward) {
        [UIView animateWithDuration:0.1 animations:^{
            self.contentOffset = CGPointMake(0, -1*self.contentInset.top);
        }];
    }
}

- (void)reloadDataWithCoolAnimationType:(CoolRefreshAnimationStyle)style {
    [self reloadData];
    
    if (style == CoolRefreshAnimationStyleNone) {
        return;
    } else if (style == CoolRefreshAnimationStyleForward) {
        self.contentOffset = CGPointMake(0, -1*self.contentInset.top);
    }
    
    animationStyle = style;
    
    CATransition *animation = [CATransition animation];
    [animation setDelegate:self];
    
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
