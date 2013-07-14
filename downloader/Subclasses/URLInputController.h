//
//  URLInputController.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/18/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface URLInputController : TransparentAlert

- (id)initWithCompletionBlock:(void (^)(NSString *url))block;

@property (nonatomic, strong) UITextField *tv;

@end
