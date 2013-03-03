//
//  DTCustomColoredAccessory.h
//  SwiftLoad
//
//  Created by Nate Symer on 4/27/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DTCustomColoredAccessory : UIControl

@property (nonatomic, retain) UIColor *accessoryColor;
@property (nonatomic, retain) UIColor *highlightedColor;

+ (DTCustomColoredAccessory *)accessoryWithColor:(UIColor *)color;


@end
