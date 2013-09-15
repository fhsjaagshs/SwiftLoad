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

@interface TextToggleControl : UIButton

@property (nonatomic, assign) BOOL on;

- (void)setColor:(UIColor *)color forState:(ToggleControlMode)state;

+ (TextToggleControl *)control;

@end
