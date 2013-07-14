//
//  pictureView.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 10/27/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZoomingImageView.h"

@interface pictureView : UIViewController <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIActionSheet *popupQuery;
@property (nonatomic, strong) ZoomingImageView *zoomingImageView;
@property (nonatomic, strong) UIBarButtonItem *prevImg;
@property (nonatomic, strong) UIBarButtonItem *nextImg;
@property (nonatomic, strong) ShadowedNavBar *navBar;
@property (nonatomic, strong) ShadowedToolbar *toolBar;

@end
