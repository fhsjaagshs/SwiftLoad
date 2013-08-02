//
//  CircularProgressView.h
//  Swift
//
//  Created by Nathaniel Symer on 8/1/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CircularProgressView : UIView

- (void)drawGreen;
- (void)drawRed;

@property (nonatomic, assign, setter = setProgress:) float progress;

@end
