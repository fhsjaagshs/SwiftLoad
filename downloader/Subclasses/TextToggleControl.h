//
//  TextToggleControl.h
//  Swift
//
//  Created by Nathaniel Symer on 9/13/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    ToggleControlModeOff,
    ToggleControlModeOn,
    ToggleControlModeIntermediate
} ToggleControlMode;

@interface TextToggleControl : UIControl

@property (nonatomic, assign) ToggleControlMode currentMode;
@property (nonatomic, strong) NSString *text;

- (void)setColor:(UIColor *)color forState:(ToggleControlMode)state;
- (void)setMode:(ToggleControlMode)mode;

@end
