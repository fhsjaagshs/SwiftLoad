//
//  FTPLoginController.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 3/24/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "SFTPLoginController.h"
#import <objc/runtime.h>

@interface SFTPLoginController () <UIAlertViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) UITextField *serverField;
@property (nonatomic, strong) UITextField *usernameField;
@property (nonatomic, strong) UITextField *passwordField;
@property (nonatomic, assign) BOOL urlPredefined;

@end

@implementation SFTPLoginController

- (void)setupTextViews {
    self.serverField = [[UITextField alloc]init];
    _serverField.keyboardAppearance = UIKeyboardAppearanceAlert;
    _serverField.borderStyle = UITextBorderStyleLine;
    _serverField.backgroundColor = [UIColor whiteColor];
    _serverField.returnKeyType = UIReturnKeyNext;
    _serverField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _serverField.autocorrectionType = UITextAutocorrectionTypeNo;
    _serverField.placeholder = @"sftp://example.com/home/me/";
    _serverField.font = [UIFont boldSystemFontOfSize:18];
    _serverField.adjustsFontSizeToFitWidth = YES;
    _serverField.delegate = self;
    _serverField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _serverField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _serverField.layer.borderWidth = 1.5;
    _serverField.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.usernameField = [[UITextField alloc]init];
    _usernameField.keyboardAppearance = UIKeyboardAppearanceAlert;
    _usernameField.borderStyle = UITextBorderStyleLine;
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
    _usernameField.layer.borderWidth = 1.5;
    _usernameField.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.passwordField = [[UITextField alloc]init];
    _passwordField.keyboardAppearance = UIKeyboardAppearanceAlert;
    _passwordField.borderStyle = UITextBorderStyleLine;
    _passwordField.backgroundColor = [UIColor whiteColor];
    _passwordField.returnKeyType = UIReturnKeyDone;
    _passwordField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _passwordField.autocapitalizationType = UITextAutocorrectionTypeNo;
    _passwordField.placeholder = @"Password";
    _passwordField.font = [UIFont boldSystemFontOfSize:18];
    _passwordField.adjustsFontSizeToFitWidth = YES;
    _passwordField.secureTextEntry = YES;
    _passwordField.delegate = self;
    _passwordField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _passwordField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _passwordField.layer.borderWidth = 1.5;
    _passwordField.layer.borderColor = [UIColor whiteColor].CGColor;
    
    _serverField.text = [[NSUserDefaults standardUserDefaults]objectForKey:@"sftp.server_name"];
    _usernameField.text = [[NSUserDefaults standardUserDefaults]objectForKey:@"sftp.user_name"];
    
    [_serverField addTarget:self action:@selector(moveOnServerField) forControlEvents:UIControlEventEditingDidEndOnExit];
    [_usernameField addTarget:self action:@selector(moveOnUsernameField) forControlEvents:UIControlEventEditingDidEndOnExit];
    [_passwordField addTarget:self.passwordField action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
    
    [self addSubview:_serverField];
    [self addSubview:_usernameField];
    [self addSubview:_passwordField];
}

- (id)initWithType:(SFTPLoginControllerType)type andCompletionHandler:(void (^)(NSString *username, NSString *password, NSString *url))block {
    switch (type) {
        case SFTPLoginControllerTypeDownload:
            self = [super initWithTitle:@"FTP Login Required" message:@"\n\n\n\n\n" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Download", nil];
            break;
        case SFTPLoginControllerTypeUpload:
            self = [super initWithTitle:@"FTP Login Required" message:@"\n\n\n\n\n" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Upload", nil];
            break;
        case SFTPLoginControllerTypeLogin:
            self = [super initWithTitle:@"FTP Login Required" message:@"\n\n\n\n\n" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Login", nil];
            break;
        default:
            break;
    }
    
    if (self) {
        objc_setAssociatedObject(self, "blockCallback", [block copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self setupTextViews];
    }
    return self;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.firstOtherButtonIndex) {
        [[NSUserDefaults standardUserDefaults]setObject:_serverField.text forKey:@"sftp.server_name"];
        [[NSUserDefaults standardUserDefaults]setObject:_usernameField.text forKey:@"sftp.user_name"];
        void (^block)(NSString *username, NSString *password, NSString *url) = objc_getAssociatedObject(self, "blockCallback");
        block(_usernameField.text, _passwordField.text, _serverField.text);
    } else {
        void (^block)(NSString *username, NSString *password, NSString *url) = objc_getAssociatedObject(self, "blockCallback");
        block(@"cancel", nil, _serverField.text);
    }
}

- (void)setUrl:(NSString *)url isPredefined:(BOOL)isPredef {
    _serverField.text = url;
    _serverField.hidden = isPredef;
    self.urlPredefined = isPredef;
    self.message = isPredef?@"\n\n\n":self.message;
}

- (void)setType:(SFTPLoginControllerType)type {
    switch (type) {
        case SFTPLoginControllerTypeDownload:
            [self addButtonWithTitle:@"Download"];
            break;
        case SFTPLoginControllerTypeUpload:
            [self addButtonWithTitle:@"Upload"];
            break;
        case SFTPLoginControllerTypeLogin:
            [self addButtonWithTitle:@"Login"];
            break;
        default:
            break;
    }
}

- (void)show {
    [super show];
    
    if (_urlPredefined) {
        [_usernameField becomeFirstResponder];
        
        if (_usernameField.text.length > 0) {
            [self moveOnUsernameField];
        }
    } else {
        [_serverField becomeFirstResponder];
        
        if (_serverField.text.length > 0) {
            [self moveOnServerField];
        }
        
        if (_usernameField.text.length > 0) {
            [self moveOnUsernameField];
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication]statusBarOrientation])) {
        if (_urlPredefined) {
            _serverField.hidden = YES;
            _usernameField.frame = CGRectMake(13, 35, 257, 30);
            _passwordField.frame = CGRectMake(13, 70, 257, 30);
        } else {
            _serverField.hidden = NO;
            _serverField.frame = CGRectMake(13, 30, 257, 25);
            _usernameField.frame = CGRectMake(13, 57, 257, 25);
            _passwordField.frame = CGRectMake(13, 84, 257, 25);
        }
    } else {
        if (_urlPredefined) {
            _serverField.hidden = YES;
            _usernameField.frame = CGRectMake(13, 48, 257, 30);
            _passwordField.frame = CGRectMake(13, 85, 257, 30);
            self.message = @"\n\n\n";
        } else {
            _serverField.hidden = NO;
            _serverField.frame = CGRectMake(13, 48, 257, 30);
            _usernameField.frame = CGRectMake(13, 85, 257, 30);
            _passwordField.frame = CGRectMake(13, 122, 257, 30);
            self.message = @"\n\n\n\n\n";
        }
    }
    
    for (UIView *view in self.subviews) {
        if ([view isKindOfClass:[UILabel class]]) {
            if ([[(UILabel *)view text]isEqualToString:self.message]) {
                [view setHidden:YES];
            }
        }
        
        if ([view isKindOfClass:[UIControl class]] && ![view isKindOfClass:[UITextField class]]) {
            if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication]statusBarOrientation])) {
                view.frame = CGRectMake(view.frame.origin.x+2.5, view.frame.origin.y+(_urlPredefined?10:15), view.frame.size.width-5, 31);
            } else {
                view.frame = CGRectMake(view.frame.origin.x+2.5, view.frame.origin.y, view.frame.size.width-5, 37);
            }
        }
    }
}

- (void)moveOnServerField {
    if ([_serverField isFirstResponder]) {
        [_serverField resignFirstResponder];
    }
    [_usernameField becomeFirstResponder];
    
    if (_textFieldDelegate && [_textFieldDelegate respondsToSelector:_didMoveOnSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [_textFieldDelegate performSelector:_didMoveOnSelector withObject:self];
#pragma clang diagnostic pop
    }
}

- (void)moveOnUsernameField {
    if ([_usernameField isFirstResponder]) {
        [_usernameField resignFirstResponder];
    }
    [_passwordField becomeFirstResponder];
}

- (void)dealloc {
    [self setTextFieldDelegate:nil];
}

@end
