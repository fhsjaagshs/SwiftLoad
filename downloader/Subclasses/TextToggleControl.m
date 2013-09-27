//
//  TextToggleControl.m
//  Swift
//
//  Created by Nathaniel Symer on 9/13/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "TextToggleControl.h"

@interface TextToggleControl ()

@property (nonatomic, strong) UIColor *onColor;
@property (nonatomic, strong) UIColor *offColor;

@end

@implementation TextToggleControl

+ (TextToggleControl *)control {
    TextToggleControl *control = [TextToggleControl buttonWithType:UIButtonTypeCustom];
    [control setup];
    return control;
}

- (void)setup {
    [self addTarget:self action:@selector(touchUp) forControlEvents:UIControlEventTouchUpInside];
}

- (void)touchUp {
    self.on = !_on;
}

- (void)setOn:(BOOL)on {
    _on = on;
    [self setTitleColor:_on?_onColor:_offColor forState:UIControlStateNormal];
}

- (void)setColor:(UIColor *)color forState:(ToggleControlMode)state {
    if (state == ToggleControlModeOn) {
        self.onColor = color;
    } else if (state == ToggleControlModeOff) {
        self.offColor = color;
    } else if (state == ToggleControlModeIntermediate) {
        [self setTitleColor:color forState:UIControlStateHighlighted];
    }
}

@end
