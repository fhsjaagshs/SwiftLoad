
#import "PullToRefreshView.h"
#import "Common.h"

#define TEXT_COLOR	 [UIColor colorWithRed:(87.0/255.0) green:(108.0/255.0) blue:(137.0/255.0) alpha:1.0]
#define FLIP_ANIMATION_DURATION 0.18f


#define SHADOW_HEIGHT 20.0
#define SHADOW_INVERSE_HEIGHT 10.0
#define SHADOW_RATIO (SHADOW_INVERSE_HEIGHT / SHADOW_HEIGHT)


@interface PullToRefreshView (Private)

@property (nonatomic, assign) PullToRefreshViewState state;

@end

@implementation PullToRefreshView
@synthesize delegate, scrollView;

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
        [activityView startAnimating]; 
    } else {
        [activityView stopAnimating];
    }
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:(animated ? 0.1f : 0.0)];
    arrowImage.opacity = (shouldShow ? 0.0 : 1.0);
    [UIView commitAnimations];
}

- (void)setImageFlipped:(BOOL)flipped {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.1f];
    arrowImage.transform = (flipped ? CATransform3DMakeRotation(M_PI * 2, 0.0f, 0.0f, 1.0f) : CATransform3DMakeRotation(M_PI, 0.0f, 0.0f, 1.0f));
    [UIView commitAnimations];
}

- (id)initWithScrollView:(UIScrollView *)scroll {
    CGRect frame = CGRectMake(0.0f, 0.0f - scroll.bounds.size.height, scroll.bounds.size.width, scroll.bounds.size.height);
    
    if (self = [super initWithFrame:frame]) {
        scrollView = scroll;
        [scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:NULL];

		self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.backgroundColor = [UIColor clearColor];
        
        statusLabel = [[UILabel alloc]initWithFrame:CGRectMake(0.0f, frame.size.height - 38.0f, self.frame.size.width, 20.0f)];
		statusLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            statusLabel.font = [UIFont boldSystemFontOfSize:18.0f];
        } else {
            statusLabel.font = [UIFont boldSystemFontOfSize:13.0f];
        }

		statusLabel.textColor = [UIColor whiteColor];
		statusLabel.shadowColor = [UIColor darkGrayColor];
		statusLabel.shadowOffset = CGSizeMake(-1, -1);
		statusLabel.backgroundColor = [UIColor clearColor];
		statusLabel.textAlignment = UITextAlignmentCenter;
		[self addSubview:statusLabel];
        [statusLabel release];

        
		arrowImage = [[CALayer alloc]init];
        arrowImage.frame = CGRectMake(25.0f, frame.size.height - 60.0f, 30.7f, 52.0f); // 30.7f was 24.0f
		arrowImage.contentsGravity = kCAGravityCenter;
        arrowImage.contentsScale = 2; // scale down the image regardless of retina. The image is by default the retina size.
        arrowImage.contents = (id)[self getArrowImage].CGImage;
		[self.layer addSublayer:arrowImage];
        [arrowImage release];

        activityView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
		activityView.frame = CGRectMake(30.0f, frame.size.height - 38.0f, 20.0f, 20.0f);
		[self addSubview:activityView];
        [activityView release];

		[self setState:PullToRefreshViewStateNormal];
        [scrollView release];
    }

    return self;
}

#pragma mark -
#pragma mark Setters

- (void)setState:(PullToRefreshViewState)state_ {
    state = state_;

	switch (state) {
		case PullToRefreshViewStateReady:
			statusLabel.text = @"Release to refresh...";
			[self showActivity:NO animated:NO];
            [self setImageFlipped:YES];
            scrollView.contentInset = UIEdgeInsetsZero;
			break;

		case PullToRefreshViewStateNormal:
			statusLabel.text = @"Pull down to refresh...";
			[self showActivity:NO animated:NO];
            [self setImageFlipped:NO];
            scrollView.contentInset = UIEdgeInsetsZero;
			break;

		case PullToRefreshViewStateLoading:
			statusLabel.text = @"Loading...";
			[self showActivity:YES animated:YES];
            [self setImageFlipped:NO];
            scrollView.contentInset = UIEdgeInsetsMake(60.0f, 0.0f, 0.0f, 0.0f);
			break;

		default:
			break;
	}
}

#pragma mark -
#pragma mark UIScrollView

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"contentOffset"]) {
        if (scrollView.isDragging) {
            if (state == PullToRefreshViewStateReady) {
                if (scrollView.contentOffset.y > -65.0f && scrollView.contentOffset.y < 0.0f) 
                    [self setState:PullToRefreshViewStateNormal];
            } else if (state == PullToRefreshViewStateNormal) {
                if (scrollView.contentOffset.y < -65.0f)
                    [self setState:PullToRefreshViewStateReady];
            } else if (state == PullToRefreshViewStateLoading) {
                if (scrollView.contentOffset.y >= 0)
                    scrollView.contentInset = UIEdgeInsetsZero;
                else
                    scrollView.contentInset = UIEdgeInsetsMake(MIN(-scrollView.contentOffset.y, 60.0f), 0, 0, 0);
            }
        } else {
            if (state == PullToRefreshViewStateReady) {
                [UIView beginAnimations:nil context:NULL];
                [UIView setAnimationDuration:0.2f];
                [self setState:PullToRefreshViewStateLoading];
                [UIView commitAnimations];

                if ([delegate respondsToSelector:@selector(pullToRefreshViewShouldRefresh:)])
                    [delegate pullToRefreshViewShouldRefresh:self];
            }
        }
    }
}

- (void)finishedLoading {
    if (state == PullToRefreshViewStateLoading) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.3f];
        [self setState:PullToRefreshViewStateNormal];
        [UIView commitAnimations];
    }
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
	[scrollView removeObserver:self forKeyPath:@"contentOffset"];
    [super dealloc];
}

@end
