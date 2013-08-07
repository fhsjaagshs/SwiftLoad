//
//  ZoomingImageViewTwo.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 3/6/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZoomingImageView : UIScrollView <UIScrollViewDelegate>

- (void)zoomOut;
- (void)resetImage;
- (void)loadImage:(UIImage *)image;

@property (nonatomic, strong) UIImageView *theImageView;

@end
