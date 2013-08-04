//
//  Upload.m
//  Swift
//
//  Created by Nathaniel Symer on 8/3/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "Upload.h"

@implementation Upload

- (NSString *)verb {
    return @"Uploading";
}

- (void)start {
    [[NetworkActivityController sharedController]show];
    [super start];
}

- (void)showFailure {
    [[NetworkActivityController sharedController]hideIfPossible];
    [super showFailure];
}

- (void)showSuccess {
    [[NetworkActivityController sharedController]hideIfPossible];
    [super showSuccess];
}

@end
