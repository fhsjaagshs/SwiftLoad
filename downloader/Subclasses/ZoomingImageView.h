//
//  ZoomingImageViewTwo.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 3/6/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZoomingImageView : UIScrollView

- (void)zoomOut;
- (void)resetImage;

@property (nonatomic, strong) UIImage *image;

@end
