//
//  HUDProgressView.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/15/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "HUDProgressView.h"

@interface WhiteFlatProgressView : UIView;

@property (nonatomic, assign) float progress;
@property (nonatomic, assign) float isIndeterminate;
@property (nonatomic, assign) BOOL redrawGreen;
@property (nonatomic, assign) BOOL redrawRed;

@end

@interface HUDProgressView ()

@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) WhiteFlatProgressView *wfpView;

@end

@implementation HUDProgressView

- (void)setIndeterminate:(float)isIndeterminate {
    _isIndeterminate = isIndeterminate;
    _wfpView.isIndeterminate = isIndeterminate;
}

- (void)setText:(NSString *)text {
    if (_text != text) {
        [_text release];
        _text = [text retain];
        _textLabel.text = text;
    }
}

- (void)redrawRed {
    _wfpView.redrawRed = YES;
    _wfpView.redrawGreen = NO;
    [_wfpView setNeedsDisplay];
}

- (void)redrawGreen {
    _wfpView.redrawGreen = YES;
    _wfpView.redrawRed = NO;
    [_wfpView setNeedsDisplay];
}

- (float)progress {
    return _wfpView.progress;
}

- (void)setProgress:(float)progress {
    [_wfpView setProgress:progress];
}

- (void)show {
    [[((downloaderAppDelegate *)[[UIApplication sharedApplication]delegate])window]addSubview:self];
}

- (void)hide {
    _wfpView.redrawRed = NO;
    _wfpView.redrawGreen = NO;
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
        self.textLabel = [[[UILabel alloc]initWithFrame:CGRectMake(0, 25, self.frame.size.width, 20)]autorelease];
        self.wfpView = [[[WhiteFlatProgressView alloc]initWithFrame:CGRectMake(10, 5, self.frame.size.width-20, 20)]autorelease];
        _wfpView.backgroundColor = [UIColor clearColor];
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
    UIWindow *window = [((downloaderAppDelegate *)[[UIApplication sharedApplication]delegate])window];
    HUDProgressView *pview = (HUDProgressView *)[window viewWithTag:tag];
    
    if (!pview) {
        pview = [[[[self class]alloc]init]autorelease];
        pview.tag = tag;
        pview.frame = CGRectMake(10, [UIScreen mainScreen].bounds.size.height-60-(60*tag), [UIScreen mainScreen].applicationFrame.size.width-20, 50);
    }
    return pview;
}

+ (HUDProgressView *)progressView {
    
    UIWindow *window = [((downloaderAppDelegate *)[[UIApplication sharedApplication]delegate])window];
    
	NSArray *subviews = window.subviews;
	Class hudClass = [HUDProgressView class];
	for (UIView *view in subviews) {
		if ([view isKindOfClass:hudClass]) {
            return (HUDProgressView *)view;
		}
	}
    
    return [[[[self class]alloc]init]autorelease];
}

@end

@implementation WhiteFlatProgressView

- (void)setIsIndeterminate:(float)isIndeterminate {
    _isIndeterminate = isIndeterminate;
    [self setNeedsDisplay];
}

- (void)setProgress:(float)progress {
    _progress = progress;
    self.redrawRed = NO;
    self.redrawGreen = NO;
    self.isIndeterminate = NO;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    UIBezierPath *outsidePath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:10];
    CGRect smallerBounds = CGRectMake(5, 5, self.bounds.size.width-10, self.bounds.size.height-10);
    UIBezierPath *insidePath = [UIBezierPath bezierPathWithRoundedRect:smallerBounds cornerRadius:10];
    CGRect finalSmallBounds = CGRectMake(6.5, 6.5, self.bounds.size.width-13, self.bounds.size.height-13);
    UIBezierPath *smallestPath = [UIBezierPath bezierPathWithRoundedRect:finalSmallBounds cornerRadius:10];
    
    CGContextSaveGState(context);
    
    if (_redrawGreen) {
        UIColor *greenColor = [UIColor colorWithRed:174.0f/255.0f green:242.0f/255.0f blue:187.0f/255.0f alpha:1.0f];
        CGContextSetFillColorWithColor(context, greenColor.CGColor);
        CGContextSetStrokeColorWithColor(context, greenColor.CGColor);
    } else if (_redrawRed) {
        UIColor *redColor = [UIColor colorWithRed:1.0f green:135.0f/255.0f blue:135.0f/255.0f alpha:1.0f];
        CGContextSetFillColorWithColor(context, redColor.CGColor);
        CGContextSetStrokeColorWithColor(context, redColor.CGColor);
    } else {
        CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
        CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    }
    
    CGContextSetLineWidth(context, 3);
    CGContextAddPath(context, outsidePath.CGPath);
    CGContextClip(context);
    CGContextAddPath(context, insidePath.CGPath);
    CGContextStrokePath(context);
    CGContextAddPath(context, smallestPath.CGPath);
    CGContextClip(context);
    
    if (_redrawGreen) {
        float distance = (self.bounds.size.width-10+1.5);
        CGRect fillRect = CGRectMake(5, 5, distance, self.bounds.size.height-10);
        CGContextFillRect(context, fillRect);
    } else if (_redrawRed) {
        float distance = (self.bounds.size.width-10+1.5);
        CGRect fillRect = CGRectMake(5, 5, distance, self.bounds.size.height-10);
        CGContextFillRect(context, fillRect);
    } else {
        if (_isIndeterminate) {
            
            CGFloat spacer = 20.0f;
            int rows = (self.bounds.size.width+(self.bounds.size.height/spacer));
            CGMutablePathRef hatchPath = CGPathCreateMutable();
            
            for (int i = 1; i <= rows; i++) {
                CGPathMoveToPoint(hatchPath, nil, (spacer*i), 0.0f);
                CGPathAddLineToPoint(hatchPath, nil, 0.0f, spacer*i);
            }
            
            CGContextAddPath(context, hatchPath);
            CGPathRelease(hatchPath);
            
            CGContextSetLineWidth(context, 7);
            CGContextSetLineCap(context, kCGLineCapRound);
            CGContextDrawPath(context, kCGPathStroke);
        } else {
            float lineCompensation = 1.45;
            float distance = (self.bounds.size.width-10+lineCompensation)*_progress;
            CGRect fillRect = CGRectMake(5, 5, distance, self.bounds.size.height-10);
            
            CGContextFillRect(context, fillRect);
        }
    }
    
    CGContextRestoreGState(context);
}

@end
