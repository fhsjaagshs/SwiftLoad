//
//  ZoomingImageViewTwo.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 3/6/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "ZoomingImageView.h"

@implementation ZoomingImageView

- (void)zoomOut {
    [self zoomToRect:self.frame animated:YES];
    self.zoomScale = 1;
}

- (void)setup {
    self.multipleTouchEnabled = YES;
    self.maximumZoomScale = 5;
    self.minimumZoomScale = 1;
    self.delegate = self;
    self.showsVerticalScrollIndicator = YES;
    self.showsHorizontalScrollIndicator = YES;
    self.backgroundColor = [UIColor clearColor];
    
    self.theImageView = [[[UIImageView alloc]initWithFrame:self.bounds]autorelease];
    self.theImageView.backgroundColor = [UIColor clearColor];
    self.theImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.theImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self addSubview:self.theImageView];
}

- (void)loadImage:(UIImage *)image {
    self.theImageView.image = image;
    self.contentSize = self.theImageView.image.size;
}

- (void)resetAfterRotate {
    self.zoomScale = 1;
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
    return self.theImageView;
}

- (void)dealloc {
    [self setTheImageView:nil];
    [super dealloc];
}

@end
