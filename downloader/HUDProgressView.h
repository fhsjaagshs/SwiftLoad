//
//  HUDProgressView.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/15/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HUDProgressView : UIView

- (void)show;
- (void)hide;
- (void)hideAfterDelay:(float)delay;

- (void)setText:(NSString *)text;

+ (HUDProgressView *)progressView;

@property (nonatomic, assign) float progress;
@property (nonatomic, strong, setter=setText:) NSString *text;
@property (nonatomic, assign, setter=setIndeterminate:) float isIndeterminate;

@end
