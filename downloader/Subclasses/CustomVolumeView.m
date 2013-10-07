//
//  CustomVolumeView.m
//  Swift
//
//  Created by Nathaniel Symer on 8/16/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "CustomVolumeView.h"

@implementation CustomVolumeView

- (UIImage *)routeButtonImageForState:(UIControlState)state {
    UIImage *image = [super routeButtonImageForState:state];
    return [image imageFilledWith:[UIColor colorWithRed:105.0f/255.0f green:54.0f/255.0f blue:153.0f/255.0f alpha:0.0f]];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        [self setMinimumVolumeSliderImage:[UIImage imageNamed:@"trackImage"] forState:UIControlStateNormal];
        [self setMaximumVolumeSliderImage:[UIImage imageNamed:@"trackImage"] forState:UIControlStateNormal];
        [self setVolumeThumbImage:[UIImage imageNamed:@"scrubber_volume"] forState:UIControlStateNormal];
        [self setVolumeThumbImage:[UIImage imageNamed:@"scrubber_volume"] forState:UIControlStateHighlighted];
        self.showsRouteButton = YES;
        for (UIView *view in self.subviews) {
            if ([view isKindOfClass:[UIButton class]]) {
                NSLog(@"%@",view);
            }
        }
    }
    return self;
}

@end
