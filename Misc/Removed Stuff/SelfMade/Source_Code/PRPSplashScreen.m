//
//  PRPSplashScreen.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 12/26/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "PRPSplashScreen.h"

@implementation PRPSplashScreen

@synthesize delegate;

- (void)loadView {
    UIView *iv = [[UIView alloc]initWithFrame:[UIScreen mainScreen].bounds];
    iv.backgroundColor = [UIColor clearColor];
    self.view = iv;
    [iv release];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    SEL didAppearSelector = @selector(splashScreenDidAppear:);
    if ([self.delegate respondsToSelector:didAppearSelector]) {
        [self.delegate splashScreenDidAppear:self];
    }
    [self dismissModalViewControllerAnimated:YES];
}

- (void)dealloc {
    self.delegate = nil;;
    [super dealloc];
}

@end
