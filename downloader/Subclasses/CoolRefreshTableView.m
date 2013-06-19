//
//  CoolRefreshTableView.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/18/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "CoolRefreshTableView.h"

@interface CoolRefreshTableView ()

@property (nonatomic, assign) CoolRefreshAnimationStyle animationStyle;

@end

@implementation CoolRefreshTableView

- (void)animationDidStart:(CAAnimation *)anim {
    if (_animationStyle == CoolRefreshAnimationStyleForward) {
        self.contentOffset = CGPointZero;
    }
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if (_animationStyle == CoolRefreshAnimationStyleBackward) {
        [UIView animateWithDuration:0.1 animations:^{
            self.contentOffset = CGPointZero;
        }];
    }
}

- (void)reloadDataWithCoolAnimationType:(CoolRefreshAnimationStyle)style {
    
    [self reloadData];
    
    self.animationStyle = style;
    
    if (style == CoolRefreshAnimationStyleNone) {
        return;
    }
    
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
