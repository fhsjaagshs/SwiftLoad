//
//  webBrowser.h
//  SwiftLoad
//
//  Created by Nate Symer on 5/8/12.
//  Copyright 2012 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomTextField.h"

@interface webBrowser : UIViewController <UITextFieldDelegate, UIWebViewDelegate>

@property (nonatomic, retain) UIActivityIndicatorView *aiv;
@property (nonatomic, retain) UIWebView *theWebView;
@property (nonatomic, retain) UIToolbar *toolBar;
@property (nonatomic, retain) CustomTextField *theTextField;
@property (nonatomic, retain) UIBarButtonItem *back;
@property (nonatomic, retain) UIBarButtonItem *forward;

@end
