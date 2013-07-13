//
//  HamburgerButton.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 7/13/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "HamburgerButton.h"
#import "HamburgerView.h"

@interface HamburgerButton : UIButton

+ (HamburgerButton *)buttonWithView:(UIView *)view;

@property (nonatomic, assign) HamburgerView *hamburgerView;
@property (nonatomic, assign) UIView *viewToMove;

@end

@implementation HamburgerButtonItem

+ (HamburgerButtonItem *)itemWithView:(UIView *)viewToMove {
    HamburgerButtonItem *item = [[[HamburgerButtonItem alloc]initWithCustomView:[HamburgerButton buttonWithView:viewToMove]]autorelease];
    
    
    return item;
}

- (void)setHamburgerView:(HamburgerView *)view {
    [(HamburgerButton *)self.customView setHamburgerView:view];
}

@end

@implementation HamburgerButton

+ (HamburgerButton *)buttonWithView:(UIView *)view {
    HamburgerButton *button = (HamburgerButton *)[HamburgerButton customizedButton];
    button.viewToMove = view;
    return button;
}

- (void)toggleState {
    if (_hamburgerView.superview) {
        [UIView animateWithDuration:0.3f animations:^{
            CGRectMake(0, _viewToMove.frame.origin.y, _viewToMove.frame.size.width, _viewToMove.frame.size.height);
        } completion:^(BOOL finished) {
            [_hamburgerView removeFromSuperview];
        }];
    } else {
        [_viewToMove insertSubview:_hamburgerView belowSubview:_viewToMove];
        [UIView animateWithDuration:0.3f animations:^{
            
        } completion:^(BOOL finished) {
            
        }];
        
    }
}

/*- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    // make sure the hamburger view is there
    // maybe fade it in via alpha
    
    CGPoint point = [_viewToMove convertPoint:[[touches anyObject]locationInView:self] fromView:self];
    CGSize screenSize = [[UIScreen mainScreen]applicationFrame].size;
    
    if (point.x > 1 && point.x < (screenSize.width-50)) {
        _viewToMove.frame = CGRectMake(point.x, _viewToMove.frame.origin.y, _viewToMove.frame.size.width, _viewToMove.frame.size.height);
    }
}*/

@end
