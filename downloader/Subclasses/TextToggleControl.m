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
@property (nonatomic, strong) UIColor *pressedColor;

@property (nonatomic, assign) BOOL isCurrentlyPressed;

@end


@implementation TextToggleControl

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addTarget:self action:@selector(touchDown) forControlEvents:UIControlEventTouchDown];
        [self addTarget:self action:@selector(touchUp) forControlEvents:UIControlEventTouchUpInside];
        [self addTarget:self action:@selector(touchesMovedOutside) forControlEvents:UIControlEventTouchDragOutside];
        [self addTarget:self action:@selector(touchesCameBackIn) forControlEvents:UIControlEventTouchDragInside];
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        [self addTarget:self action:@selector(touchDown) forControlEvents:UIControlEventTouchDown];
        [self addTarget:self action:@selector(touchUp) forControlEvents:UIControlEventTouchUpInside];
        [self addTarget:self action:@selector(touchesMovedOutside) forControlEvents:UIControlEventTouchDragOutside];
        [self addTarget:self action:@selector(touchesCameBackIn) forControlEvents:UIControlEventTouchDragInside];
    }
    return self;
}

- (void)touchesCameBackIn {
    self.isCurrentlyPressed = YES;
    [self setNeedsDisplay];
}

- (void)touchesMovedOutside {
    self.isCurrentlyPressed = NO;
    [self setNeedsDisplay];
}

- (void)touchUp {
    self.isCurrentlyPressed = NO;
    if (_currentMode == ToggleControlModeOff) {
        self.currentMode = ToggleControlModeOn;
    } else {
        self.currentMode = ToggleControlModeOff;
    }
    [self setNeedsDisplay];
}

- (void)touchDown {
    self.isCurrentlyPressed = YES;
    [self setNeedsDisplay];
}

- (void)setMode:(ToggleControlMode)mode {
    self.currentMode = mode;
    [self setNeedsDisplay];
}

- (void)setText:(NSString *)text {
    _text = text;
}

- (void)setColor:(UIColor *)color forState:(ToggleControlMode)state {
    if (state == ToggleControlModeOn) {
        self.onColor = color;
    } else if (state == ToggleControlModeOff) {
        self.offColor = color;
    } else if (state == ToggleControlModeIntermediate) {
        self.pressedColor = color;
    }
}

- (void)drawRect:(CGRect)rect {
    UIColor *currentColor = _isCurrentlyPressed?_pressedColor:(_currentMode == ToggleControlModeOn)?_onColor:_offColor;
    [currentColor set];
    
    UIFont *font = [UIFont boldSystemFontOfSize:15];
    float width = [_text widthForHeight:self.bounds.size.height font:font];
    float x_pos = (self.bounds.size.width-width)/2;
    [_text drawAtPoint:CGPointMake(self.bounds.origin.x+x_pos, self.bounds.origin.y) withAttributes:@{NSFontAttributeName:font}];
}

@end
