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

@property (nonatomic, assign) UISwipeGestureRecognizerDirection direction;
@property (nonatomic, assign) BOOL animating;

@end

@implementation SwipeCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.right = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipe:)];
        _right.direction = UISwipeGestureRecognizerDirectionRight;
        [self.contentView addGestureRecognizer:_right];
        
        self.left = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipe:)];
        _left.direction = UISwipeGestureRecognizerDirectionLeft;
        [self.contentView addGestureRecognizer:_left];
        
        self.contentView.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)hideWithAnimation:(BOOL)shouldAnimate {
    CGRect frame = self.contentView.frame;
    frame.origin.x = 0;
    
    if (_delegate && [_delegate respondsToSelector:@selector(swipeCellWillHide:)]) {
        [_delegate swipeCellWillHide:self];
    }
    
    if (shouldAnimate) {
        self.animating = YES;
        
        __weak SwipeCell *weakself = self;
        
        [UIView animateWithDuration:0.2f animations:^{
            weakself.contentView.frame = frame;
        } completion:^(BOOL finished) {
            weakself.animating = NO;
            weakself.backgroundView = nil;
        }];
    } else {
        self.contentView.frame = frame;
        self.backgroundView = nil;
    }
}

- (void)swipe:(UISwipeGestureRecognizer *)rec {
    self.direction = rec.direction;
    
    CGRect frame = self.contentView.frame;
    
    BOOL isHiding = NO;
    
    NSLog(@"Swipe: %@",rec);
    
    if (frame.origin.x == 0) {
        frame.origin.x = (_direction == UISwipeGestureRecognizerDirectionRight)?self.bounds.size.width:-self.bounds.size.width;
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
    
    self.animating = YES;
    
    __weak SwipeCell *weakself = self;
    
    [UIView animateWithDuration:0.2f animations:^{
        weakself.contentView.frame = frame;
    } completion:^(BOOL finished) {
        weakself.animating = NO;
        
        if (isHiding) {
            weakself.backgroundView = nil;
        } else {
            [self.backgroundView addGestureRecognizer:_left];
            [self.backgroundView addGestureRecognizer:_right];
        }

        if (weakself.delegate && [weakself.delegate respondsToSelector:@selector(swipeCellDidReveal:)]) {
            [weakself.delegate swipeCellDidReveal:self];
        }
    }];
}

- (void)setSwipeEnabled:(BOOL)swipeEnabled {
    _swipeEnabled = swipeEnabled;
    _right.enabled = _swipeEnabled;
    _left.enabled = _swipeEnabled;
}

@end