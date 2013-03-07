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
    self.zoomScale = 1;
}

- (void)setup {
    self.multipleTouchEnabled = YES;
    self.maximumZoomScale = 5.0;
    self.minimumZoomScale = 1.0;
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
    [self fixContentSize];
}

- (void)fixContentSize {
    NSLog(@"%@",NSStringFromCGSize(self.contentSize));
    if ((self.theImageView.image.size.width < self.theImageView.image.size.height)) {
        float ratio = self.theImageView.image.size.height/self.theImageView.bounds.size.height;
        self.contentSize = CGSizeMake(self.theImageView.image.size.width/ratio, self.theImageView.image.size.height/ratio);
    } else {
        float ratio = self.theImageView.image.size.width/self.theImageView.bounds.size.width;
        self.contentSize = CGSizeMake(self.theImageView.image.size.width/ratio, self.theImageView.image.size.height/ratio);
    }
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

@end
