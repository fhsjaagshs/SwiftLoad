//
//  pictureView.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 10/27/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomToolbar.h"
#import "ZoomingImageView.h"

@interface pictureView : UIViewController <UIGestureRecognizerDelegate>

@property (nonatomic, retain) UIActionSheet *popupQuery;
@property (nonatomic, retain) ZoomingImageView *zoomingImageView;
@property (nonatomic, retain) UIBarButtonItem *prevImg;
@property (nonatomic, retain) UIBarButtonItem *nextImg;
@property (nonatomic, retain) UINavigationBar *navBar;
@property (nonatomic, retain) UIToolbar *toolBar;

@end
