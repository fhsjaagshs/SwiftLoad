//
//  ContentOffsetThingy.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/18/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "ContentOffsetWatchdog.h"

@interface ContentOffsetWatchdog () <UIScrollViewDelegate>

@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, strong) UILabel *statusLabel;

@property (nonatomic, strong) NSString *initialTextInternal;
@property (nonatomic, strong) NSString *trippedTextInternal;

@property (nonatomic, assign) BOOL shouldReturnToNormal;

@end

@implementation ContentOffsetWatchdog

+ (id)watchdogWithScrollView:(UIScrollView *)scrollView {
    return [[[self class]alloc]initWithScrollView:scrollView];
}

- (id)initWithScrollView:(UIScrollView *)scroll {
    CGRect frame = CGRectMake(0, -1*(60+scroll.contentInset.top), scroll.bounds.size.width, 60+scroll.contentInset.top);
    self = [super initWithFrame:frame];
    if (self) {
        self.statusLabel = [[UILabel alloc]initWithFrame:CGRectMake(0.0f, frame.size.height-38.0f, self.frame.size.width, 20.0f)];
		_statusLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _statusLabel.font = [UIFont boldSystemFontOfSize:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)?18:13];
		_statusLabel.textColor = [UIColor darkGrayColor];
		_statusLabel.shadowOffset = CGSizeZero;
		_statusLabel.backgroundColor = [UIColor clearColor];
		_statusLabel.textAlignment = NSTextAlignmentCenter;
		[self addSubview:_statusLabel];
        
        [self setScrollView:scroll];
        [_scrollView addSubview:self];
        [_scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:NULL];
    }
    return self;
}

- (void)setMode:(WatchdogMode)mode {
    _mode = mode;
    _statusLabel.hidden = (_mode == WatchdogModeNormal);
}

- (void)resetOffset {
    _scrollView.contentOffset = CGPointMake(0, 0);
}

- (void)setInitialText:(NSString *)text {
    _statusLabel.text = text;
    self.initialTextInternal = text;
}

- (void)setTrippedText:(NSString *)text {
    self.trippedTextInternal = text;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"contentOffset"]) {
        if (_scrollView.isDragging) {
            if (_mode == WatchdogModeNormal) {
                if (_scrollView.contentOffset.y < -30-_scrollView.contentInset.top) {
                    if ([_delegate respondsToSelector:@selector(shouldTripWatchdog:)]) {
                        if ([_delegate shouldTripWatchdog:self] && [_delegate respondsToSelector:@selector(watchdogWasTripped:)]) {
                            [_delegate watchdogWasTripped:self];
                        }
                    }
                }
            } else if (_mode == WatchdogModePullToRefresh) {
                if (_scrollView.isDragging) {
                    if (_scrollView.contentOffset.y < -60-_scrollView.contentInset.top) {
                        _statusLabel.text = _trippedTextInternal;
                        self.shouldReturnToNormal = YES;
                    } else {
                        self.shouldReturnToNormal = NO;
                        _statusLabel.text = _initialTextInternal;
                    }
                } else {
                    if (_shouldReturnToNormal) {
                        self.shouldReturnToNormal = NO;
                        _statusLabel.text = _initialTextInternal;
                        if ([_delegate respondsToSelector:@selector(shouldTripWatchdog:)]) {
                            if ([_delegate shouldTripWatchdog:self] && [_delegate respondsToSelector:@selector(watchdogWasTripped:)]) {
                                [_delegate watchdogWasTripped:self];
                            }
                        }
                    }
                }
            }
        }
    }
}

- (void)dealloc {
	[_scrollView removeObserver:self forKeyPath:@"contentOffset"];
}

@end
