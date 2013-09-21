//
//  SwipeCell.m
//  Swift
//
//  Created by Nathaniel Symer on 9/20/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "SwipeCell.h"

@interface SwipeCell ()

@property (nonatomic, strong) UISwipeGestureRecognizer *left;
@property (nonatomic, strong) UISwipeGestureRecognizer *right;

@property (nonatomic, assign) BOOL animating;

@end

@implementation SwipeCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        self.left = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipe:)];
        _left.direction = UISwipeGestureRecognizerDirectionLeft;
        [self.contentView addGestureRecognizer:_left];
        
        self.right = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipe:)];
        _right.direction = UISwipeGestureRecognizerDirectionRight;
        [self.contentView addGestureRecognizer:_right];

        self.contentView.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)hideWithAnimation:(BOOL)shouldAnimate {
    
    if (_animating) {
        return;
    }
    
    if (self.contentView.frame.origin.x != 0) {
        return;
    }
    
    self.animating = YES;
    
    CGRect frame = self.contentView.frame;
    frame.origin.x = 0;
    
    if (_delegate && [_delegate respondsToSelector:@selector(swipeCellWillHide:)]) {
        [_delegate swipeCellWillHide:self];
    }
    
    if (shouldAnimate) {
        [UIView animateWithDuration:0.2f animations:^{
            self.contentView.frame = frame;
        } completion:^(BOOL finished) {
            self.backgroundView = nil;
            [self.contentView addGestureRecognizer:_left];
            [self.contentView addGestureRecognizer:_right];
            self.animating = NO;
        }];
    } else {
        self.contentView.frame = frame;
        self.backgroundView = nil;
        [self.contentView addGestureRecognizer:_left];
        [self.contentView addGestureRecognizer:_right];
        self.animating = NO;
    }
}

- (void)swipe:(UISwipeGestureRecognizer *)rec {
    
    self.animating = YES;
    
    CGRect frame = self.contentView.frame;
    
    BOOL isHiding = NO;

    if (frame.origin.x == 0) {
        frame.origin.x = (rec.direction == UISwipeGestureRecognizerDirectionRight)?self.bounds.size.width:-self.bounds.size.width;
        self.backgroundView = [_delegate backgroundViewForSwipeCell:self];

        if (_delegate && [_delegate respondsToSelector:@selector(swipeCellWillReveal:)]) {
            [_delegate swipeCellWillReveal:self];
        }
        
    } else {
        frame.origin.x = 0;
        if (_delegate && [_delegate respondsToSelector:@selector(swipeCellWillHide:)]) {
            [_delegate swipeCellWillHide:self];
        }
        isHiding = YES;
    }

    [UIView animateWithDuration:0.2f animations:^{
        self.contentView.frame = frame;
    } completion:^(BOOL finished) {
        self.animating = NO;
        if (isHiding) {
            self.backgroundView = nil;
            [self.contentView addGestureRecognizer:_left];
            [self.contentView addGestureRecognizer:_right];
        } else {
            [self.backgroundView addGestureRecognizer:_left];
            [self.backgroundView addGestureRecognizer:_right];
            if (_delegate && [_delegate respondsToSelector:@selector(swipeCellDidReveal:)]) {
                [_delegate swipeCellDidReveal:self];
            }
        }
    }];
}

- (void)setSwipeEnabled:(BOOL)swipeEnabled {
    _swipeEnabled = swipeEnabled;
    _right.enabled = _swipeEnabled;
    _left.enabled = _swipeEnabled;
}

@end