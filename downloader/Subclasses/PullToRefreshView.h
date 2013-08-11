
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

typedef enum {
    PullToRefreshViewStateNormal = 0,
	PullToRefreshViewStateReady,
	PullToRefreshViewStateLoading
} PullToRefreshViewState;

@protocol PullToRefreshViewDelegate;

@interface PullToRefreshView : UIView 

@property (nonatomic, weak) id<PullToRefreshViewDelegate> delegate;
@property (nonatomic, assign, setter=setState:) PullToRefreshViewState state;

@property (nonatomic, strong) UILabel *statusLabel;

- (void)finishedLoading;
- (id)initWithScrollView:(UIScrollView *)scrollView;

- (void)setState:(PullToRefreshViewState)state_;

@end

@protocol PullToRefreshViewDelegate <NSObject>

@optional
- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view;

@end
