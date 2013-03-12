//
//  UIViewController+AutoNib.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 10/29/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "UIViewController+AutoNib.h"

@implementation UIViewController (AutoNib)

- (id)initWithAutoNib {
    BOOL isPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    NSString *class = NSStringFromClass([self class]);
    self = [self initWithNibName:isPad?[class stringByAppendingString:@"~iPad"]:class bundle:nil];
    return self;
}

+ (id)viewController {
    return [[[[self class]alloc]init]autorelease];
}

+ (id)viewControllerNib {
    return [[[[self class]alloc]initWithAutoNib]autorelease];
}

@end
