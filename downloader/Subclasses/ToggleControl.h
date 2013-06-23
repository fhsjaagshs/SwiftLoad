//
//  ToggleControl.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/22/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    ToggleControlModeOff,
    ToggleControlModeOn,
    ToggleControlModeIntermediate
} ToggleControlMode;

@interface ToggleControl : UIControl

//@property (nonatomic, assign) BOOL on;
@property (nonatomic, assign) ToggleControlMode currentMode;

- (void)setImage:(UIImage *)image forState:(ToggleControlMode)state;
- (void)setMode:(ToggleControlMode)mode;

@end
