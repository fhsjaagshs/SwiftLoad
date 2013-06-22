//
//  TransparentAlert.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/21/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "TransparentAlert.h"

@implementation TransparentAlert

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0.6 alpha:0.6];
        // create views
    }
    return self;
}

//
// TODO:
// Finish methods
// Add completion block

- (void)show {
    // add to main window
}

- (void)dismiss {
    // remove from main window
}

- (void)layoutSubviews {
    // setup views and shit
}

@end
