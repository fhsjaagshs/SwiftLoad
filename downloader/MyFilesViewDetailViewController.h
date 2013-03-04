//
//  MyFilesViewDetailViewController.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 8/11/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomAlertView.h"

@interface MyFilesViewDetailViewController : UIViewController <UIWebViewDelegate>

@property (nonatomic, retain) UIActionSheet *popupQuery;
@property (nonatomic, retain) UIWebView *webView;

@end
