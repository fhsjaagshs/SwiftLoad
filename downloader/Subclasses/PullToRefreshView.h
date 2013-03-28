
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

typedef enum {
    PullToRefreshViewStateNormal = 0,
	PullToRefreshViewStateReady,
	PullToRefreshViewStateLoading
} PullToRefreshViewState;

@protocol PullToRefreshViewDelegate;

@interface PullToRefreshView : UIView {
	id<PullToRefreshViewDelegate> delegate;
    UIScrollView *scrollView;
	PullToRefreshViewState state;

	UILabel *statusLabel;
	CALayer *arrowImage;
	UIActivityIndicatorView *activityView;
}

@property (nonatomic, readonly) UIScrollView *scrollView;
@property (nonatomic, assign) id<PullToRefreshViewDelegate> delegate;

- (void)finishedLoading;
- (id)initWithScrollView:(UIScrollView *)scrollView;

- (void)setState:(PullToRefreshViewState)state_;

@end

@protocol PullToRefreshViewDelegate <NSObject>

@optional
- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view;

@end
