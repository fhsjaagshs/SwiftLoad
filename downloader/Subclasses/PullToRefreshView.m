
#import "PullToRefreshView.h"
#import "Common.h"

#define TEXT_COLOR	 [UIColor colorWithRed:(87.0/255.0) green:(108.0/255.0) blue:(137.0/255.0) alpha:1.0]
#define FLIP_ANIMATION_DURATION 0.18f


#define SHADOW_HEIGHT 20.0
#define SHADOW_INVERSE_HEIGHT 10.0
#define SHADOW_RATIO (SHADOW_INVERSE_HEIGHT / SHADOW_HEIGHT)


@interface PullToRefreshView ()

@property (nonatomic, retain) UILabel *statusLabel;
@property (nonatomic, retain) CALayer *arrowImage;
@property (nonatomic, retain) UIActivityIndicatorView *activityView;
@property (nonatomic, retain) UIScrollView *scrollView;

@end

@implementation PullToRefreshView
@synthesize delegate, scrollView, state, statusLabel, arrowImage, activityView;

- (UIImage *)getArrowImage {
    CGFloat width = 56.4f;
    CGFloat height = 90.0f;
    CGFloat padding = 7.0f;
    
    UIGraphicsBeginImageContext(CGSizeMake(56.4f, 104.0f));		
    CGContextRef context = UIGraphicsGetCurrentContext();		
    UIGraphicsPushContext(context);								
    
    CGColorRef lightColor = LIGHT_BLUE;
    CGColorRef darkColor = DARK_BLUE; 
    
    CGContextSaveGState(context);
    CGMutablePathRef overallPath = CGPathCreateMutable();
    
    CGPathMoveToPoint(overallPath, nil, width/2, padding);
    CGPathAddLineToPoint(overallPath, nil, width/2, padding);
    CGPathAddLineToPoint(overallPath, nil, width, (height/2)+padding);
    CGPathAddLineToPoint(overallPath, nil, (width/3)*2.2, (height/2)+padding);
    CGPathAddLineToPoint(overallPath, nil, (width/3)*2.2, height+padding);
    CGPathAddLineToPoint(overallPath, nil, (width/3)*0.8, height+padding);
    CGPathAddLineToPoint(overallPath, nil, (width/3)*0.8, (height/2)+padding);
    CGPathAddLineToPoint(overallPath, nil, 0, (height/2)+padding);
    CGPathAddLineToPoint(overallPath, nil, width/2, padding);
    
    CGContextAddPath(context, overallPath);
    CGContextClip(context);
    drawGlossAndGradient(context, CGRectMake(0, 0, 56.4f, 104.0f), lightColor, darkColor);  
    
    CGContextRestoreGState(context);
    CGContextSaveGState(context);
    
    CGContextAddPath(context, overallPath);
    CGContextSetLineWidth(context, 2.0f);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextDrawPath(context, kCGPathStroke);
    
    CGContextRestoreGState(context);  
    CGPathRelease(overallPath);

    UIGraphicsPopContext();								
    
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    return outputImage;
}

- (UIColor *)getGradientTextColor {
    
    UIGraphicsBeginImageContext(CGSizeMake(5.0f, 20.0f));		
    CGContextRef context = UIGraphicsGetCurrentContext();		
    UIGraphicsPushContext(context);
    
    drawGlossAndGradient(context, CGRectMake(0, 0, 5.0f, 20.0f), LIGHT_BLUE, DARK_BLUE);  
    
    UIGraphicsPopContext();								
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return [UIColor colorWithPatternImage:outputImage];
}

- (void)showActivity:(BOOL)shouldShow animated:(BOOL)animated {
    if (shouldShow) {
        [self.activityView startAnimating];
    } else {
        [self.activityView stopAnimating];
    }
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:(animated ? 0.1f : 0.0)];
    self.arrowImage.opacity = (shouldShow ? 0.0 : 1.0);
    [UIView commitAnimations];
}

- (void)setImageFlipped:(BOOL)flipped {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.1f];
    self.arrowImage.transform = (flipped ? CATransform3DMakeRotation(M_PI * 2, 0.0f, 0.0f, 1.0f) : CATransform3DMakeRotation(M_PI, 0.0f, 0.0f, 1.0f));
    [UIView commitAnimations];
}

- (id)initWithScrollView:(UIScrollView *)scroll {
    CGRect frame = CGRectMake(0.0f, 0.0f - scroll.bounds.size.height, scroll.bounds.size.width, scroll.bounds.size.height);
    
    if (self = [super initWithFrame:frame]) {
        self.scrollView = scroll;
        [self.scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:NULL];

		self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.backgroundColor = [UIColor clearColor];
        
        self.statusLabel = [[[UILabel alloc]initWithFrame:CGRectMake(0.0f, frame.size.height - 38.0f, self.frame.size.width, 20.0f)]autorelease];
		self.statusLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.statusLabel.font = [UIFont boldSystemFontOfSize:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)?18:13];
		self.statusLabel.textColor = [UIColor whiteColor];
		self.statusLabel.shadowColor = [UIColor darkGrayColor];
		self.statusLabel.shadowOffset = CGSizeMake(-1, -1);
		self.statusLabel.backgroundColor = [UIColor clearColor];
		self.statusLabel.textAlignment = UITextAlignmentCenter;
		[self addSubview:self.statusLabel];
        
		self.arrowImage = [[[CALayer alloc]init]autorelease];
        self.arrowImage.frame = CGRectMake(25.0f, frame.size.height - 50.0f, 30.7f, 52.0f); // 30.7f was 24.0f
		self.arrowImage.contentsGravity = kCAGravityCenter;
        self.arrowImage.contentsScale = 2; // scale down the image regardless of retina. The image is by default the retina size.
        self.arrowImage.contents = (id)[self getArrowImage].CGImage;
		[self.layer addSublayer:self.arrowImage];

        self.activityView = [[[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite]autorelease];
		self.activityView.frame = CGRectMake(30.0f, frame.size.height - 38.0f, 20.0f, 20.0f);
		[self addSubview:self.activityView];

		[self setState:PullToRefreshViewStateNormal];
    }

    return self;
}

- (void)setState:(PullToRefreshViewState)state_ {
    state = state_;

	switch (self.state) {
		case PullToRefreshViewStateReady:
			self.statusLabel.text = @"Release to refresh...";
			[self showActivity:NO animated:NO];
            [self setImageFlipped:YES];
            self.scrollView.contentInset = UIEdgeInsetsZero;
			break;

		case PullToRefreshViewStateNormal:
			self.statusLabel.text = @"Pull down to refresh...";
			[self showActivity:NO animated:NO];
            [self setImageFlipped:NO];
            self.scrollView.contentInset = UIEdgeInsetsZero;
			break;

		case PullToRefreshViewStateLoading:
			self.statusLabel.text = @"Loading...";
			[self showActivity:YES animated:YES];
            [self setImageFlipped:NO];
            self.scrollView.contentInset = UIEdgeInsetsMake(60.0f, 0.0f, 0.0f, 0.0f);
			break;

		default:
			break;
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"contentOffset"]) {
        if (self.scrollView.isDragging) {
            if (self.state == PullToRefreshViewStateReady) {
                if (self.scrollView.contentOffset.y > -65.0f && self.scrollView.contentOffset.y < 0.0f)
                    [self setState:PullToRefreshViewStateNormal];
            } else if (self.state == PullToRefreshViewStateNormal) {
                if (self.scrollView.contentOffset.y < -65.0f)
                    [self setState:PullToRefreshViewStateReady];
            } else if (self.state == PullToRefreshViewStateLoading) {
                if (self.scrollView.contentOffset.y >= 0) {
                    self.scrollView.contentInset = UIEdgeInsetsZero;
                } else {
                    self.scrollView.contentInset = UIEdgeInsetsMake(MIN(-self.scrollView.contentOffset.y, 30.0f), 0, 0, 0);
                }
            }
        } else {
            if (self.state == PullToRefreshViewStateReady) {
                [UIView beginAnimations:nil context:NULL];
                [UIView setAnimationDuration:0.2f];
                [self setState:PullToRefreshViewStateLoading];
                [UIView commitAnimations];

                if ([self.delegate respondsToSelector:@selector(pullToRefreshViewShouldRefresh:)])
                    [self.delegate pullToRefreshViewShouldRefresh:self];
            }
        }
    }
}

- (void)finishedLoading {
    if (self.state == PullToRefreshViewStateLoading) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.1f]; // 0.3f
        [self setState:PullToRefreshViewStateNormal];
        [UIView commitAnimations];
    }
}

- (void)dealloc {
	[self.scrollView removeObserver:self forKeyPath:@"contentOffset"];
    [self setDelegate:nil];
    [super dealloc];
}

@end
