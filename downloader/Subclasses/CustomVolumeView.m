//
//  CustomVolumeView.m
//  Swift
//
//  Created by Nathaniel Symer on 8/16/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "CustomVolumeView.h"

@implementation CustomVolumeView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {

        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        
        if ([[[UIDevice currentDevice]systemVersion]floatValue] < 6.0f) {
            Class volSlider = NSClassFromString(@"MPVolumeSlider");
            
            for (UIView *view in self.subviews) {
                view.hidden = NO;
                if ([view isKindOfClass:volSlider]) {
                    UISlider *slider = (UISlider *)view;
                    [slider setBackgroundColor:[UIColor clearColor]];
                    [slider setMinimumTrackImage:[UIImage imageNamed:@"trackImage"] forState:UIControlStateNormal];
                    [slider setMaximumTrackImage:[UIImage imageNamed:@"trackImage"] forState:UIControlStateNormal];
                    [slider setThumbImage:[UIImage imageNamed:@"scrubber_volume"] forState:UIControlStateNormal];
                    [slider setThumbImage:[UIImage imageNamed:@"scrubber_volume"] forState:UIControlStateHighlighted];
                }
            }
        } else {
            [self setMinimumVolumeSliderImage:[UIImage imageNamed:@"trackImage"] forState:UIControlStateNormal];
            [self setMaximumVolumeSliderImage:[UIImage imageNamed:@"trackImage"] forState:UIControlStateNormal];
            [self setVolumeThumbImage:[UIImage imageNamed:@"scrubber_volume"] forState:UIControlStateNormal];
            [self setVolumeThumbImage:[UIImage imageNamed:@"scrubber_volume"] forState:UIControlStateHighlighted];
        }
    }
    return self;
}

@end
