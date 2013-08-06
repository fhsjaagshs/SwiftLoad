//
//  ZoomingImageViewTwo.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 3/6/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "ZoomingImageView.h"

@interface ZoomingImageView ()

@end

@implementation ZoomingImageView

- (void)zoomOut {
    [self zoomToRect:self.frame animated:YES];
    self.zoomScale = self.minimumZoomScale;
    [self setNeedsLayout];
}

- (void)setup {
    self.multipleTouchEnabled = YES;
    self.delegate = self;
    self.showsVerticalScrollIndicator = YES;
    self.showsHorizontalScrollIndicator = YES;
    self.backgroundColor = [UIColor clearColor];
    
    self.theImageView = [[UIImageView alloc]initWithFrame:CGRectZero];
    _theImageView.backgroundColor = [UIColor clearColor];
    _theImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self addSubview:_theImageView];
}

- (void)loadImage:(UIImage *)image {
    _theImageView.image = image;
    
    CGRect photoImageViewFrame;
    photoImageViewFrame.origin = CGPointZero;
    photoImageViewFrame.size = image.size;
    
    _theImageView.frame = photoImageViewFrame;
    self.contentSize = photoImageViewFrame.size;
    
    [self setMaxMinZoomScalesForCurrentBounds];
}

- (void)resetAfterRotate {
    [self loadImage:_theImageView.image]; // a bit of a hack
    self.zoomScale = self.minimumZoomScale;
}

- (id)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _theImageView;
}

- (void)setMaxMinZoomScalesForCurrentBounds {
    
	// Bail
	if (!_theImageView.image) {
        return;
    }
    
	// Sizes
    CGSize boundsSize = self.bounds.size;
    CGSize imageSize = _theImageView.frame.size;
    
    // Calculate Min
    CGFloat xScale = boundsSize.width/imageSize.width;
    CGFloat yScale = boundsSize.height/imageSize.height;
    CGFloat minScale = MIN(xScale, yScale);

	self.maximumZoomScale = minScale*5;
	self.minimumZoomScale = minScale;
	self.zoomScale = self.minimumZoomScale;
    
	_theImageView.frame = CGRectMake(0, 0, _theImageView.frame.size.width, _theImageView.frame.size.height);
	[self setNeedsLayout];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
    // Center the image as it becomes smaller than the size of the screen
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = _theImageView.frame;
    
    // Horizontally
    if (frameToCenter.size.width < boundsSize.width) {
        frameToCenter.origin.x = floorf((boundsSize.width-frameToCenter.size.width) / 2.0);
	} else {
        frameToCenter.origin.x = 0;
	}
    
    // Vertically
    if (frameToCenter.size.height < boundsSize.height) {
        frameToCenter.origin.y = floorf((boundsSize.height-frameToCenter.size.height) / 2.0);
	} else {
        frameToCenter.origin.y = 0;
	}
    
	// Center
	_theImageView.frame = frameToCenter;
}

@end
