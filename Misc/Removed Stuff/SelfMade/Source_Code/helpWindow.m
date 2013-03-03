//
//  helpWindow.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 9/17/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import "helpWindow.h"

@implementation helpWindow

- (IBAction)back {
    [self dismissModalViewControllerAnimated:YES];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    NSLog(@"%@ dealloc'd", NSStringFromClass([self class]));
    [super dealloc];
}

@end
