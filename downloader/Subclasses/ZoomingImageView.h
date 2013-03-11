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
- (void)resetAfterRotate;
- (void)loadImage:(UIImage *)image;

@property (nonatomic, retain) UIImageView *theImageView;

@end
