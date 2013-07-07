//
//  FTPLoginController.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 3/24/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "FTPLoginController.h"
#import <objc/runtime.h>

@interface FTPLoginController () <UIAlertViewDelegate, UITextFieldDelegate>

@property (nonatomic, retain) UITextField *serverField;
@property (nonatomic, retain) UITextField *usernameField;
@property (nonatomic, retain) UITextField *passwordField;
@property (nonatomic, assign) BOOL urlPredefined;

@end

@implementation FTPLoginController

@synthesize serverField, usernameField, passwordField, urlPredefined, textFieldDelegate;

- (void)setSFTP:(BOOL)isSFTP {
    _isSFTP = isSFTP;
    self.title = _isSFTP?@"SFTP Login Required":@"FTP Login Required";
    self.serverField.text = [[NSUserDefaults standardUserDefaults]objectForKey:_isSFTP?@"sftp.server_name":@"ftp.server_name"];
    self.usernameField.text = [[NSUserDefaults standardUserDefaults]objectForKey:_isSFTP?@"sftp.user_name":@"ftp.user_name"];
    [self.serverField setPlaceholder:_isSFTP?@"sftp://example.com/home/me/":@"ftp://example.com/from/webroot/"];
}

- (void)setupTextViews {
    self.serverField = [[[UITextField alloc]init]autorelease];
    [self.serverField setKeyboardAppearance:UIKeyboardAppearanceAlert];
    [self.serverField setBorderStyle:UITextBorderStyleBezel];
    [self.serverField setBackgroundColor:[UIColor whiteColor]];
    [self.serverField setReturnKeyType:UIReturnKeyNext];
    [self.serverField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [self.serverField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self.serverField setPlaceholder:_isSFTP?@"sftp://example.com/home/me/":@"ftp://example.com/from/webroot/"];
    [self.serverField setFont:[UIFont boldSystemFontOfSize:18]];
    [self.serverField setAdjustsFontSizeToFitWidth:YES];
    [self.serverField setDelegate:self];
    [self.serverField setClearButtonMode:UITextFieldViewModeWhileEditing];
    self.serverField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    
    self.usernameField = [[[UITextField alloc]init]autorelease];
    [self.usernameField setKeyboardAppearance:UIKeyboardAppearanceAlert];
    [self.usernameField setBorderStyle:UITextBorderStyleBezel];
    [self.usernameField setBackgroundColor:[UIColor whiteColor]];
    [self.usernameField setReturnKeyType:UIReturnKeyNext];
    [self.usernameField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [self.usernameField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self.usernameField setPlaceholder:@"Username"];
    [self.usernameField setFont:[UIFont boldSystemFontOfSize:18]];
    [self.usernameField setAdjustsFontSizeToFitWidth:YES];
    self.usernameField.delegate = self;
    self.usernameField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.usernameField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    
    self.passwordField = [[[UITextField alloc]init]autorelease];
    [self.passwordField setKeyboardAppearance:UIKeyboardAppearanceAlert];
    [self.passwordField setBorderStyle:UITextBorderStyleBezel];
    [self.passwordField setBackgroundColor:[UIColor whiteColor]];
    [self.passwordField setReturnKeyType:UIReturnKeyNext];
    [self.passwordField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [self.passwordField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self.passwordField setPlaceholder:@"Password"];
    [self.passwordField setFont:[UIFont boldSystemFontOfSize:18]];
    [self.passwordField setAdjustsFontSizeToFitWidth:YES];
    self.passwordField.secureTextEntry = YES;
    self.passwordField.delegate = self;
    self.passwordField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.passwordField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    
    self.serverField.text = [[NSUserDefaults standardUserDefaults]objectForKey:_isSFTP?@"sftp.server_name":@"ftp.server_name"];
    self.usernameField.text = [[NSUserDefaults standardUserDefaults]objectForKey:_isSFTP?@"sftp.user_name":@"ftp.user_name"];
    
    [self.serverField addTarget:self action:@selector(moveOnServerField) forControlEvents:UIControlEventEditingDidEndOnExit];
    [self.usernameField addTarget:self action:@selector(moveOnUsernameField) forControlEvents:UIControlEventEditingDidEndOnExit];
    [self.passwordField addTarget:self.passwordField action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
    
    [self addSubview:self.serverField];
    [self addSubview:self.usernameField];
    [self addSubview:self.passwordField];
}

- (id)initWithType:(FTPLoginControllerType)type andCompletionHandler:(void (^)(NSString *username, NSString *password, NSString *url))block {
    switch (type) {
        case FTPLoginControllerTypeDownload:
            self = [super initWithTitle:@"FTP Login Required" message:@"\n\n\n\n\n" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Download", nil];
            break;
        case FTPLoginControllerTypeUpload:
            self = [super initWithTitle:@"FTP Login Required" message:@"\n\n\n\n\n" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Upload", nil];
            break;
        case FTPLoginControllerTypeLogin:
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
        [[NSUserDefaults standardUserDefaults]setObject:self.serverField.text forKey:_isSFTP?@"sftp.server_name":@"ftp.server_name"];
        [[NSUserDefaults standardUserDefaults]setObject:self.usernameField.text forKey:_isSFTP?@"sftp.user_name":@"ftp.user_name"];
        void (^block)(NSString *username, NSString *password, NSString *url) = objc_getAssociatedObject(self, "blockCallback");
        block(self.usernameField.text, self.passwordField.text, self.serverField.text);
        Block_release(block);
    } else {
        void (^block)(NSString *username, NSString *password, NSString *url) = objc_getAssociatedObject(self, "blockCallback");
        block(@"cancel", nil, self.serverField.text);
        Block_release(block);
    }
}

- (void)setUrl:(NSString *)url isPredefined:(BOOL)isPredef {
    self.serverField.text = url;
    [self.serverField setHidden:isPredef];
    self.urlPredefined = isPredef;
    self.message = isPredef?@"\n\n\n":self.message;
}

- (void)setType:(FTPLoginControllerType)type {
    switch (type) {
        case FTPLoginControllerTypeDownload:
            [self addButtonWithTitle:@"Download"];
            break;
        case FTPLoginControllerTypeUpload:
            [self addButtonWithTitle:@"Upload"];
            break;
        case FTPLoginControllerTypeLogin:
            [self addButtonWithTitle:@"Login"];
            break;
        default:
            break;
    }
}

- (void)show {
    [super show];
    
    if (self.urlPredefined) {
        
        [self.usernameField becomeFirstResponder];
        
        if (self.usernameField.text.length > 0) {
            [self moveOnUsernameField];
        }
        
    } else {
        
        [self.serverField becomeFirstResponder];
        
        if (self.serverField.text.length > 0) {
            [self moveOnServerField];
        }
        
        if (self.usernameField.text.length > 0) {
            [self moveOnUsernameField];
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication]statusBarOrientation])) {
        if (self.urlPredefined) {
            [self.serverField setHidden:YES];
            self.usernameField.frame = CGRectMake(13, 35, 257, 30);
            self.passwordField.frame = CGRectMake(13, 70, 257, 30);
        } else {
            [self.serverField setHidden:NO];
            self.serverField.frame = CGRectMake(13, 30, 257, 25);
            self.usernameField.frame = CGRectMake(13, 57, 257, 25);
            self.passwordField.frame = CGRectMake(13, 84, 257, 25);
        }
    } else {
        if (self.urlPredefined) {
            [self.serverField setHidden:YES];
            self.message = @"\n\n\n";
            self.usernameField.frame = CGRectMake(13, 48, 257, 30);
            self.passwordField.frame = CGRectMake(13, 85, 257, 30);
        } else {
            [self.serverField setHidden:NO];
            self.message = @"\n\n\n\n\n";
            self.serverField.frame = CGRectMake(13, 48, 257, 30);
            self.usernameField.frame = CGRectMake(13, 85, 257, 30);
            self.passwordField.frame = CGRectMake(13, 122, 257, 30);
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
                view.frame = CGRectMake(view.frame.origin.x+2.5, view.frame.origin.y+(self.urlPredefined?10:15), view.frame.size.width-5, 31);
            } else {
                view.frame = CGRectMake(view.frame.origin.x+2.5, view.frame.origin.y, view.frame.size.width-5, 37);
            }
        }
    }
}

- (void)moveOnServerField {
    if ([self.serverField isFirstResponder]) {
        [self.serverField resignFirstResponder];
    }
    [self.usernameField becomeFirstResponder];
    
    if (self.textFieldDelegate && [self.textFieldDelegate respondsToSelector:self.didMoveOnSelector]) {
        [self.textFieldDelegate performSelector:self.didMoveOnSelector withObject:self];
    }
}

- (void)moveOnUsernameField {
    if ([self.usernameField isFirstResponder]) {
        [self.usernameField resignFirstResponder];
    }
    [self.passwordField becomeFirstResponder];
}

- (void)dealloc {
    [self setTextFieldDelegate:nil];
    [super dealloc];
}

@end
