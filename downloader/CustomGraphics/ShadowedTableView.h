//
//  ShadowedTableView.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 2011/08/21.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//
//  Adapted from work done by Matt Gallagher.

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface ShadowedTableView : UITableView

@property (nonatomic, retain) CAGradientLayer *topShadow;
@property (nonatomic, retain) CAGradientLayer *bottomShadow;

@end
