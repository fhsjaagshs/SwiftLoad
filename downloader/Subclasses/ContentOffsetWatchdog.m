//
//  ContentOffsetThingy.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/18/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "ContentOffsetWatchdog.h"

@interface ContentOffsetWatchdog () <UIScrollViewDelegate>

@property (nonatomic, retain) UIScrollView *scrollView;

@end

@implementation ContentOffsetWatchdog

+ (id)watchdogWithScrollView:(UIScrollView *)scrollView {
    return [[[[self class]alloc]initWithScrollView:scrollView]autorelease];
}

- (id)initWithScrollView:(UIScrollView *)scroll {
    self = [super initWithFrame:CGRectMake(0, -1*scroll.bounds.size.height, scroll.bounds.size.width, scroll.bounds.size.height)];
    if (self) {
        [self setScrollView:scroll];
        [_scrollView addSubview:self];
        [_scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:NULL];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"contentOffset"]) {
        if ((_scrollView.isDecelerating || _scrollView.isDragging) || (_scrollView.isDragging && _scrollView.isDecelerating)) {
            if (_scrollView.contentOffset.y < -30) {
                if ([_delegate respondsToSelector:@selector(shouldTripWatchdog)]) {
                    if ([_delegate shouldTripWatchdog] && [_delegate respondsToSelector:@selector(watchdogWasTripped)]) {
                        _scrollView.contentOffset = CGPointZero;
                        [_delegate watchdogWasTripped];
                    }
                }
            }
        }
    }
}

- (void)dealloc {
    [_scrollView removeFromSuperview];
	[_scrollView removeObserver:self forKeyPath:@"contentOffset"];
    [self setScrollView:nil];
    [self setDelegate:nil];
    [super dealloc];
}

@end
