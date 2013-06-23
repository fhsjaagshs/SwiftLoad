//
//  ToggleControl.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/22/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "ToggleControl.h"

@interface ToggleControl ()

@property (nonatomic, retain) UIImage *onImage;
@property (nonatomic, retain) UIImage *offImage;
@property (nonatomic, retain) UIImage *pressedImage;

@property (nonatomic, assign) BOOL isCurrentlyPressed;

@end


@implementation ToggleControl

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addTarget:self action:@selector(touchDown) forControlEvents:UIControlEventTouchDown];
        [self addTarget:self action:@selector(touchUp) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        [self addTarget:self action:@selector(touchDown) forControlEvents:UIControlEventTouchDown];
        [self addTarget:self action:@selector(touchUp) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
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

/*- (void)sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event {
    [super sendAction:action to:target forEvent:event];
    
    
    if (event.type == UIEventTypeTouches) {
        
        UITouch *touch = [[event touchesForView:self]anyObject];
        
        // don't call setNeedsDisplay after "if" logic because there are
        // many more touch phases that we don't care about.
        // Therefore the UIControl will be redrawn when we don't need it.
        
        if (touch.phase == UITouchPhaseEnded) {
            NSLog(@"Released");
            self.isCurrentlyPressed = NO;
            if (_currentMode == ToggleControlModeOff) {
                self.currentMode = ToggleControlModeOn;
            } else {
                self.currentMode = ToggleControlModeOff;
            }
            [self setNeedsDisplay];
        } else if (touch.phase == UITouchPhaseBegan) {
            NSLog(@"Touch down");
            self.isCurrentlyPressed = YES;
            [self setNeedsDisplay];
        }
    }
}*/

- (void)setMode:(ToggleControlMode)mode {
    self.currentMode = mode;
    [self setNeedsDisplay];
}

- (void)setImage:(UIImage *)image forState:(ToggleControlMode)state {
    if (state == ToggleControlModeOn) {
        self.onImage = image;
    } else if (state == ToggleControlModeOff) {
        self.offImage = image;
    } else if (state == ToggleControlModeIntermediate) {
        self.pressedImage = image;
    }
}

- (void)drawRect:(CGRect)rect {
    [_isCurrentlyPressed?_pressedImage:(_currentMode == ToggleControlModeOn)?_onImage:_offImage drawInRect:self.bounds];
}

- (void)dealloc {
    [self setOnImage:nil];
    [self setOffImage:nil];
    [self setPressedImage:nil];
    [super dealloc];
}

@end
