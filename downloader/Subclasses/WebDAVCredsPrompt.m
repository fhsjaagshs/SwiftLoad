//
//  WebDAVCredsPrompt.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 7/9/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "WebDAVCredsPrompt.h"
#import <objc/runtime.h>

@interface WebDAVCredsPrompt () <UIAlertViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) UITextField *usernameField;
@property (nonatomic, strong) UITextField *passwordField;

@end

@implementation WebDAVCredsPrompt

- (void)setupTextViews {
    self.usernameField = [[UITextField alloc]init];
    _usernameField.frame = CGRectMake(13, 45, 257, 30);
    _usernameField.keyboardAppearance = UIKeyboardAppearanceAlert;
    _usernameField.borderStyle = UITextBorderStyleBezel;
    _usernameField.backgroundColor = [UIColor whiteColor];
    _usernameField.returnKeyType = UIReturnKeyNext;
    _usernameField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _usernameField.autocorrectionType = UITextAutocorrectionTypeNo;
    _usernameField.placeholder = @"Username";
    _usernameField.font = [UIFont boldSystemFontOfSize:18];
    _usernameField.adjustsFontSizeToFitWidth = YES;
    _usernameField.delegate = self;
    _usernameField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _usernameField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    
    self.passwordField = [[UITextField alloc]init];
    _passwordField.frame = CGRectMake(13, 85, 257, 30);
    _passwordField.keyboardAppearance = UIKeyboardAppearanceAlert;
    _passwordField.borderStyle = UITextBorderStyleBezel;
    _passwordField.backgroundColor = [UIColor whiteColor];
    _passwordField.returnKeyType = UIReturnKeyDone;
    _passwordField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _passwordField.autocorrectionType = UITextAutocorrectionTypeNo;
    _passwordField.placeholder = @"Password";
    _passwordField.font = [UIFont boldSystemFontOfSize:18];
    _passwordField.adjustsFontSizeToFitWidth = YES;
    _passwordField.secureTextEntry = YES;
    _passwordField.delegate = self;
    _passwordField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _passwordField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    
    NSDictionary *prevcreds = [SimpleKeychain load:@"webdav_creds"];
    
    _usernameField.text = [prevcreds objectForKey:@"username"];
    _passwordField.text = [prevcreds objectForKey:@"password"];
    
    [_usernameField addTarget:self action:@selector(moveOnUsernameField) forControlEvents:UIControlEventEditingDidEndOnExit];
    [_passwordField addTarget:_passwordField action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];

    [self addSubview:_usernameField];
    [self addSubview:_passwordField];
}

- (id)initWithCredsDelegate:(id<WebDAVCredsPromptCredsDelegate>)delegate {
    self = [super initWithTitle:@"Create WebDAV Login" message:@"\n\n\n" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Save", nil];
    if (self) {
        self.credsDelegate = delegate;
        [self setupTextViews];
    }
    return self;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.firstOtherButtonIndex) {
        [SimpleKeychain save:@"webdav_creds" data:@{@"username": _usernameField.text, @"password": _passwordField.text}];
        
        if (_credsDelegate && [_credsDelegate respondsToSelector:@selector(credsWereSaved)]) {
            [_credsDelegate credsWereSaved];
        }
    }
}

- (void)show {
    [super show];
    if (_usernameField.text.length > 0) {
        [_passwordField becomeFirstResponder];
    } else {
        [_usernameField becomeFirstResponder];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];

    for (UIView *view in self.subviews) {
        if ([view isKindOfClass:[UILabel class]]) {
            if ([[(UILabel *)view text]isEqualToString:self.message]) {
                [view setHidden:YES];
            }
        }
        
        if ([view isKindOfClass:[UIControl class]] && ![view isKindOfClass:[UITextField class]]) {
            if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication]statusBarOrientation])) {
                view.frame = CGRectMake(view.frame.origin.x+2.5, view.frame.origin.y+10, view.frame.size.width-5, 31);
            } else {
                view.frame = CGRectMake(view.frame.origin.x+2.5, view.frame.origin.y, view.frame.size.width-5, 37);
            }
        }
    }
}

- (void)moveOnUsernameField {
    if ([_usernameField isFirstResponder]) {
        [_usernameField resignFirstResponder];
    }
    [_passwordField becomeFirstResponder];
}

- (void)dealloc {
    [self setCredsDelegate:nil];
}

@end
