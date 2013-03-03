//
//  UIView+RemoveAllSubviews.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 12/11/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "UIView+RemoveAllSubviews.h"

@implementation UIView (RemoveAllSubviews)

- (void)removeAllSubviews {
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
}

- (void)removeAllGestureRecognizers {
    for (UIGestureRecognizer *rec in self.gestureRecognizers) {
        [self removeGestureRecognizer:rec];
    }
}

@end
