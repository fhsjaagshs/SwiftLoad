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

@property (nonatomic, retain) CustomTextField *serverField;
@property (nonatomic, retain) CustomTextField *usernameField;
@property (nonatomic, retain) CustomTextField *passwordField;
@property (nonatomic, assign) BOOL urlPredefined;
@property (nonatomic, retain) NSString *ftpURL;

@end

@implementation FTPLoginController

@synthesize serverField, usernameField, passwordField, ftpURL, urlPredefined, textFieldDelegate;

- (void)setupTextViews {
    self.serverField = [[[CustomTextField alloc]init]autorelease];
    [self.serverField setKeyboardAppearance:UIKeyboardAppearanceAlert];
    [self.serverField setBorderStyle:UITextBorderStyleBezel];
    [self.serverField setBackgroundColor:[UIColor clearColor]];
    [self.serverField setReturnKeyType:UIReturnKeyNext];
    [self.serverField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [self.serverField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self.serverField setPlaceholder:@"ftp://"];
    [self.serverField setFont:[UIFont boldSystemFontOfSize:18]];
    [self.serverField setAdjustsFontSizeToFitWidth:YES];
    [self.serverField setDelegate:self];
    [self.serverField setClearButtonMode:UITextFieldViewModeWhileEditing];
    self.serverField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    
    self.usernameField = [[[CustomTextField alloc]init]autorelease];
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
    
    self.passwordField = [[[CustomTextField alloc]init]autorelease];
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
    
    NSString *FTPPath = [[NSUserDefaults standardUserDefaults]objectForKey:@"FTPPath"];
    NSString *FTPUsername = [[NSUserDefaults standardUserDefaults]objectForKey:@"FTPUsername"];
    
    self.serverField.text = FTPPath;
    self.usernameField.text = FTPUsername;
    
    [self.serverField addTarget:self action:@selector(moveOnServerField) forControlEvents:UIControlEventEditingDidEndOnExit];
    [self.usernameField addTarget:self action:@selector(moveOnUsernameField) forControlEvents:UIControlEventEditingDidEndOnExit];
    [self.passwordField addTarget:self.passwordField action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
    
    [self addSubview:self.serverField];
    [self addSubview:self.usernameField];
    [self addSubview:self.passwordField];
}

- (id)initWithCompletionHandler:(void (^)(NSString *username, NSString *password, NSString *url))block {
    self = [super initWithTitle:@"FTP Login Required" message:@"\n\n\n\n\n" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
    if (self) {
        objc_setAssociatedObject(self, "blockCallback", [block copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self setupTextViews];
    }
    return self;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        NSString *server = (self.ftpURL.length == 0)?self.serverField.text:self.ftpURL;
        [[NSUserDefaults standardUserDefaults]setObject:server forKey:@"FTPPath"];
        [[NSUserDefaults standardUserDefaults]setObject:self.usernameField.text forKey:@"FTPUsername"];
        void (^block)(NSString *username, NSString *password, NSString *url) = objc_getAssociatedObject(self, "blockCallback");
        block(self.usernameField.text, self.passwordField.text, server);
        Block_release(block);
    } else {
        void (^block)(NSString *username, NSString *password, NSString *url) = objc_getAssociatedObject(self, "blockCallback");
        block(@"cancel", nil, (self.ftpURL.length == 0)?self.serverField.text:self.ftpURL);
        Block_release(block);
    }
}

- (void)setUrl:(NSString *)url isPredefined:(BOOL)isPredef {
    self.ftpURL = url;
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
            
            UIImage *buttonImage = [getUIButtonImageNonPressed(view.frame.size.height) resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)];
            [(UIButton *)view setBackgroundImage:buttonImage forState:UIControlStateNormal];
            
            UIImage *buttonImagePressed = [getUIButtonImagePressed(view.frame.size.height) resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)];
            [(UIButton *)view setBackgroundImage:buttonImagePressed forState:UIControlStateHighlighted];
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
