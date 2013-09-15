//
//  UIViewController+AutoNib.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 10/29/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (AutoNib)

- (instancetype)initWithAutoNib;
+ (instancetype)viewController;
+ (instancetype)viewControllerNib;
+ (instancetype)viewControllerWhite;

+ (instancetype)topViewController;

- (void)adjustViewsForiOS7;

@end
