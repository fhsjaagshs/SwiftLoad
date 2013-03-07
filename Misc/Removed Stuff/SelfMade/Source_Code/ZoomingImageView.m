//
//  ZoomingImageView.m
//  ZoomingImageView
//
//  Created by Nathaniel Symer on 7/11/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "ZoomingImageView.h"

@implementation ZoomingImageView

@synthesize theImageView;

/*- (void)setup {
    self.multipleTouchEnabled = YES;
    self.maximumZoomScale = 5.0;
    self.minimumZoomScale = 1.0;
    self.delegate = self;
    self.showsVerticalScrollIndicator = YES;
    self.showsHorizontalScrollIndicator = YES;
    self.backgroundColor = [UIColor clearColor];

    self.theImageView = [[[UIImageView alloc]initWithFrame:self.bounds]autorelease];
    self.theImageView.backgroundColor = [UIColor clearColor];
    self.theImageView.contentMode = UIViewContentModeCenter;
    [self addSubview:self.theImageView];
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
}*/

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.showsVerticalScrollIndicator = YES;
        self.showsHorizontalScrollIndicator = YES;
        self.bouncesZoom = YES;
        self.delegate = self;
        self.contentMode = UIViewContentModeScaleAspectFit;
    }
    return self;
}

- (void)layoutSubviews  {
    [super layoutSubviews];
    
    // center the zoom view as it becomes smaller than the size of the screen
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = self.theImageView.frame;
    
    // center horizontally
    if (frameToCenter.size.width < boundsSize.width)
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    else
        frameToCenter.origin.x = 0;
    
    // center vertically
    if (frameToCenter.size.height < boundsSize.height)
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    else
        frameToCenter.origin.y = 0;
    
    self.theImageView.frame = frameToCenter;
}

- (void)setFrame:(CGRect)frame {
    BOOL sizeChanging = !CGSizeEqualToSize(frame.size, self.frame.size);
    
    if (sizeChanging) {
        [self prepareToResize];
    }
    
    [super setFrame:frame];
    
    if (sizeChanging) {
        [self recoverFromResizing];
    }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.theImageView;
}

- (void)loadImage:(UIImage *)image {
    // clear the previous image
    [self.theImageView removeFromSuperview];
    self.theImageView = nil;
    
    // reset our zoomScale to 1.0 before doing any further calculations
    self.zoomScale = 1.0;
    self.theImageView = [[[UIImageView alloc]initWithImage:image]autorelease];
    [self addSubview:self.theImageView];
    
    [self configureForImageSize:image.size];
    
    self.theImageView.bounds = CGRectMake(0, 0, image.size.width*self.minimumZoomScale, image.size.height*self.minimumZoomScale);
    [self setNeedsLayout];
}

- (void)configureForImageSize:(CGSize)imageSize {
    _imageSize = imageSize;
    self.contentSize = imageSize;
    [self setMaxMinZoomScalesForCurrentBounds];
    self.zoomScale = self.minimumZoomScale;
}

- (void)setMaxMinZoomScalesForCurrentBounds
{
    CGSize boundsSize = self.bounds.size;

    CGFloat xScale = boundsSize.width/_imageSize.width;
    CGFloat yScale = boundsSize.height/_imageSize.height;

    BOOL imagePortrait = _imageSize.height > _imageSize.width;
    BOOL phonePortrait = boundsSize.height > boundsSize.width;
    CGFloat minScale = imagePortrait == phonePortrait ? xScale : MIN(xScale, yScale);

    CGFloat maxScale = 1.0/[[UIScreen mainScreen]scale];

    if (minScale > maxScale) {
        minScale = maxScale;
    }
    
    self.maximumZoomScale = maxScale;
    self.minimumZoomScale = minScale;
}

- (void)prepareToResize {
    CGPoint boundsCenter = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    _pointToCenterAfterResize = [self convertPoint:boundsCenter toView:self.theImageView];
    _scaleToRestoreAfterResize = self.zoomScale;
    
    // If we're at the minimum zoom scale, preserve that by returning 0, which will be converted to the minimum
    // allowable scale when the scale is restored.
    if (_scaleToRestoreAfterResize <= self.minimumZoomScale + FLT_EPSILON) {
        _scaleToRestoreAfterResize = 0;
    }
}

- (void)recoverFromResizing {
    [self setMaxMinZoomScalesForCurrentBounds];
    
    // Step 1: restore zoom scale, first making sure it is within the allowable range.
    CGFloat maxZoomScale = MAX(self.minimumZoomScale, _scaleToRestoreAfterResize);
    self.zoomScale = MIN(self.maximumZoomScale, maxZoomScale);
    
    // Step 2: restore center point, first making sure it is within the allowable range.
    
    // 2a: convert our desired center point back to our own coordinate space
    CGPoint boundsCenter = [self convertPoint:_pointToCenterAfterResize fromView:self.theImageView];
    
    // 2b: calculate the content offset that would yield that center point
    CGPoint offset = CGPointMake(boundsCenter.x - self.bounds.size.width / 2.0,
                                 boundsCenter.y - self.bounds.size.height / 2.0);
    
    // 2c: restore offset, adjusted to be within the allowable range
    CGPoint maxOffset = [self maximumContentOffset];
    CGPoint minOffset = [self minimumContentOffset];
    
    CGFloat realMaxOffset = MIN(maxOffset.x, offset.x);
    offset.x = MAX(minOffset.x, realMaxOffset);
    
    realMaxOffset = MIN(maxOffset.y, offset.y);
    offset.y = MAX(minOffset.y, realMaxOffset);
    
    self.contentOffset = offset;
}

- (CGPoint)maximumContentOffset {
    CGSize contentSize = self.contentSize;
    CGSize boundsSize = self.bounds.size;
    return CGPointMake(contentSize.width-boundsSize.width, contentSize.height-boundsSize.height);
}

- (CGPoint)minimumContentOffset {
    return CGPointZero;
}

/*- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    float widthRatio = frame.size.width/self.theImageView.bounds.size.width;
    float heightRatio = frame.size.height/self.theImageView.bounds.size.height;
    
    CGRect framey;
    framey.origin = self.theImageView.frame.origin;
    frame.size = CGSizeMake(self.theImageView.bounds.size.width*widthRatio, self.theImageView.bounds.size.height*heightRatio);
    self.theImageView.frame = framey;
    [self layoutSubviews];
    
}

- (void)adjustOtherStuff {
    self.maximumZoomScale = 1;
    self.minimumZoomScale = 1;
    self.zoomScale = 1;
    self.contentSize = CGSizeMake(0, 0);
    
    CGRect photoImageViewFrame;
    photoImageViewFrame.origin = CGPointZero;
    photoImageViewFrame.size = self.theImageView.image.size;
    self.theImageView.bounds = photoImageViewFrame;
    self.contentSize = photoImageViewFrame.size;
}

- (void)awakeFromNib {
    [self setup];
}

- (void)adjustFrame {
    self.maximumZoomScale = 1;
    self.minimumZoomScale = 1;
    self.zoomScale = 1;
    self.contentSize = CGSizeMake(0, 0);
    
    CGRect photoImageViewFrame;
    photoImageViewFrame.origin = CGPointZero;
    photoImageViewFrame.size = self.theImageView.image.size;
    self.theImageView.bounds = photoImageViewFrame;
    self.contentSize = photoImageViewFrame.size;
    [self setMaxMinZoomScalesForCurrentBounds];
}

- (void)loadImage:(UIImage *)image {
    [self.theImageView setImage:image];
    self.zoomScale = 1;
    [self adjustFrame];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.theImageView;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale {
    NSLog(@"Image View Frame: %@",NSStringFromCGRect(self.theImageView.frame));
}

- (void)zoomOut {
    [self zoomToPoint:CGPointMake(0, 0) withScale:self.minimumZoomScale animated:YES];
    self.zoomScale = self.minimumZoomScale;
}

- (void)setMaxMinZoomScalesForCurrentBounds {

	if (self.theImageView.image == nil) {
        return;
    }
    
    if (self.zoomScale > self.minimumZoomScale) {
        [self layoutSubviews];
        return;
    }

    self.zoomScale = self.minimumZoomScale;

    self.maximumZoomScale = 1;
    self.minimumZoomScale = 1;
    self.contentSize = CGSizeMake(0, 0);

    CGSize boundsSize = self.bounds.size;
    CGSize imageSize = self.theImageView.bounds.size;

    CGFloat xScale = boundsSize.width/imageSize.width;
    CGFloat yScale = boundsSize.height/imageSize.height;
    CGFloat minScale = MIN(xScale, yScale);

	if (xScale > 1 && yScale > 1) {
		minScale = 1.0;
	}
	
	self.maximumZoomScale = 5;
	self.minimumZoomScale = minScale;
	self.zoomScale = minScale;
	
	self.theImageView.bounds = CGRectMake(0, 0, self.theImageView.bounds.size.width, self.theImageView.bounds.size.height);
    
    [self layoutSubviews];
}

- (void)layoutSubviews {
	[super layoutSubviews];
    
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = self.theImageView.frame;

    if (frameToCenter.size.width < boundsSize.width) {
        frameToCenter.origin.x = floorf((boundsSize.width-frameToCenter.size.width)/2.0);
	} else {
        frameToCenter.origin.x = 0;
	}

    if (frameToCenter.size.height < boundsSize.height) {
        frameToCenter.origin.y = floorf((boundsSize.height-frameToCenter.size.height)/2.0);
	} else {
        frameToCenter.origin.y = 0;
	}
    
    self.theImageView.frame = frameToCenter;
}*/

- (void)dealloc {
    [self setTheImageView:nil];
    [super dealloc];
}

@end
