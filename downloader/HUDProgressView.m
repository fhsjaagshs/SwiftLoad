//
//  HUDProgressView.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/15/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "HUDProgressView.h"

@interface HUDProgressView ()

@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) WhiteProgressView *wfpView;

@end

@implementation HUDProgressView

- (void)setIndeterminate:(float)isIndeterminate {
    _isIndeterminate = isIndeterminate;
    _wfpView.isIndeterminate = isIndeterminate;
}

- (void)setText:(NSString *)text {
    if (_text != text) {
        _text = text;
        _textLabel.text = text;
    }
}

- (void)redrawRed {
    [_wfpView drawRed];
}

- (void)redrawGreen {
    [_wfpView drawGreen];
}

- (float)progress {
    return _wfpView.progress;
}

- (void)setProgress:(float)progress {
    [_wfpView setProgress:progress];
}

- (void)show {
    [[[[UIApplication sharedApplication]delegate]window]addSubview:self];
}

- (void)hide {
    _wfpView.isIndeterminate = NO;
    [self removeFromSuperview];
}

- (void)hideAfterDelay:(float)delay {
    [self performSelector:@selector(hide) withObject:nil afterDelay:delay];
}

- (id)init {
    self = [super initWithFrame:CGRectMake(10, [UIScreen mainScreen].bounds.size.height-60, [UIScreen mainScreen].applicationFrame.size.width-20, 50)];
    if (self) {
        self.userInteractionEnabled = NO;
        self.layer.cornerRadius = 10;
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        self.textLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 25, self.frame.size.width, 20)];
        self.wfpView = [[WhiteProgressView alloc]initWithFrame:CGRectMake(10, 5, self.frame.size.width-20, 20)];
        _textLabel.backgroundColor = [UIColor clearColor];
        _textLabel.textAlignment = UITextAlignmentCenter;
        _textLabel.textColor = [UIColor whiteColor];
        _textLabel.font = [UIFont boldSystemFontOfSize:12];
        [self addSubview:_wfpView];
        [self addSubview:_textLabel];
    }
    return self;
}

+ (HUDProgressView *)progressViewWithTag:(int)tag {
    UIWindow *window = [[[UIApplication sharedApplication]delegate]window];
    HUDProgressView *pview = (HUDProgressView *)[window viewWithTag:tag];
    
    if (!pview) {
        pview = [[[self class]alloc]init];
        pview.tag = tag;
        pview.frame = CGRectMake(10, [UIScreen mainScreen].bounds.size.height-60-(60*tag), [UIScreen mainScreen].applicationFrame.size.width-20, 50);
    }
    return pview;
}

+ (HUDProgressView *)progressView {
    
    UIWindow *window = [[[UIApplication sharedApplication]delegate]window];
    
	NSArray *subviews = window.subviews;
	Class hudClass = [HUDProgressView class];
	for (UIView *view in subviews) {
		if ([view isKindOfClass:hudClass]) {
            return (HUDProgressView *)view;
		}
	}
    
    return [[[self class]alloc]init];
}

@end
