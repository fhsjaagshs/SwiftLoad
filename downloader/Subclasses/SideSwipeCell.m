//
//  SideSwipeCell.m
//  Swift
//
//  Created by Nathaniel Symer on 9/19/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "SideSwipeCell.h"

@interface SideSwipeCell ()

@property (nonatomic, weak) UIView *sideSwipeView;

@end

@implementation SideSwipeCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        UISwipeGestureRecognizer *rightSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipe:)];
        rightSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
        [self addGestureRecognizer:rightSwipeGestureRecognizer];
        
        UISwipeGestureRecognizer *leftSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipe:)];
        leftSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
        [self addGestureRecognizer:leftSwipeGestureRecognizer];
    }
    
    return self;
}

- (void)swipe:(UISwipeGestureRecognizer *)recognizer {
    
    UIView *view = [_delegate viewForSideSwipeCell:self];
    
    /*_sideSwipeView.frame = CGRectMake(0, cell.frame.origin.y, cell.frame.size.width, cell.frame.size.height);
    [_theTableView insertSubview:_sideSwipeView belowSubview:cell];
    self.sideSwipeDirection = direction;
    
    // Because iOS 7 prevents animations of UITableView subviews???
    
    //_sideSwipeCell.frame = [[[UIApplication sharedApplication]keyWindow]convertRect:_sideSwipeCell.frame fromView:_theTableView];
    
    CGRect frame = _sideSwipeCell.frame;
    frame.origin.x = (direction == UISwipeGestureRecognizerDirectionRight)?cell.frame.size.width:-cell.frame.size.width;
    
    //  [_sideSwipeCell removeFromSuperview];
    //  [[[UIApplication sharedApplication]keyWindow]addSubview:_sideSwipeCell];
    
    [UIView animateWithDuration:0.2f delay:0.0f options:UIViewAnimationCurveEaseOut animations:^{
        [_sideSwipeCell setFrame:frame];
    } completion:^(BOOL finished) {
        //    [_sideSwipeCell removeFromSuperview];
        //    _sideSwipeCell.frame = [[[UIApplication sharedApplication]keyWindow]convertRect:_sideSwipeCell.frame toView:_theTableView];
        //   [_theTableView addSubview:_sideSwipeCell];
        self.animatingSideSwipe = NO;
    }];*/
    
    if (recognizer.direction == UISwipeGestureRecognizerDirectionRight) {
        NSLog(@"right");
    } else {
        NSLog(@"left");
    }
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
