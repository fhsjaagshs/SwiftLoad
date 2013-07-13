//
//  URLInputController.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/18/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "URLInputController.h"
#import <objc/runtime.h>

@implementation URLInputController

- (id)initWithCompletionBlock:(void (^)(NSString *fileName))block {
    self = [super initWithTitle:@"Enter URL to Download" message:@"\n\n\n\n" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Download",nil];
    if (self) {
        objc_setAssociatedObject(self, "blockCallback", block, OBJC_ASSOCIATION_COPY_NONATOMIC);
        
        self.message = @"Hey_man_hide_me";
        
        self.tv = [[[UITextField alloc]init]autorelease];
        _tv.keyboardAppearance = UIKeyboardAppearanceAlert;
        _tv.borderStyle = UITextBorderStyleNone;
        _tv.backgroundColor = [UIColor whiteColor];
        _tv.returnKeyType = UIReturnKeyDone;
        _tv.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _tv.autocorrectionType = UITextAutocorrectionTypeNo;
        _tv.placeholder = @"Enter URL to download here...";
        _tv.font = [UIFont systemFontOfSize:13];
        _tv.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        _tv.adjustsFontSizeToFitWidth = YES;
        _tv.clearButtonMode = UITextFieldViewModeWhileEditing;
        _tv.text = [[NSUserDefaults standardUserDefaults]objectForKey:@"myDefaults"];
        [_tv addTarget:self action:@selector(donePressed) forControlEvents:UIControlEventEditingDidEndOnExit];

        [self addSubview:_tv];
        [_tv becomeFirstResponder];
    }
    return self;
}

- (void)donePressed {
    [_tv resignFirstResponder];
    [self dismissWithClickedButtonIndex:1 animated:YES];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication]statusBarOrientation])) {
        _tv.frame = CGRectMake(15, 31, 255, 27);
    } else {
        _tv.frame = CGRectMake(15, 45, 255, 27);
    }
    
    for (UIView *view in self.subviews) {
        if ([view isKindOfClass:[UILabel class]]) {
            if ([[(UILabel *)view text]isEqualToString:self.message]) {
                [view setHidden:YES];
            }
        }
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    [self alertView:alertView clickedButtonAtIndex:buttonIndex];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        void(^block)(NSString *fileName) = objc_getAssociatedObject(self, "blockCallback");
        
        if (block) {
            block(_tv.text);
            Block_release(block);
        }
    }
    
    [[NSUserDefaults standardUserDefaults]setObject:_tv.text forKey:@"myDefaults"];
    objc_removeAssociatedObjects(self);
}

@end
