//
//  MyFilesViewDetailViewController.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 8/11/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import "DocumentViewController.h"

@interface DocumentViewController () <UIWebViewDelegate>

@property (nonatomic, strong) UIActionSheet *popupQuery;
@property (nonatomic, strong) UIWebView *webView;

@end

@implementation DocumentViewController

- (void)loadView {
    [super loadView];
    CGRect screenBounds = [[UIScreen mainScreen]bounds];
    UINavigationBar *bar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 64)];
    bar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:[kAppDelegate openFile].lastPathComponent];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showActionSheet:)];
    [bar pushNavigationItem:topItem animated:NO];
    [self.view addSubview:bar];
    
    self.webView = [[UIWebView alloc]initWithFrame:screenBounds];
    _webView.delegate = self;
    _webView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _webView.backgroundColor = [UIColor clearColor];
    _webView.contentMode = UIViewContentModeScaleAspectFit;
    _webView.scalesPageToFit = YES;
    _webView.dataDetectorTypes = UIDataDetectorTypeLink;
    _webView.layer.rasterizationScale = [[UIScreen mainScreen]scale];
    _webView.layer.shouldRasterize = YES;
   
    [self.view addSubview:_webView];
    
    [self.view bringSubviewToFront:bar];

    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:[kAppDelegate openFile]] cachePolicy:NSURLCacheStorageAllowed timeoutInterval:60.0];
    [_webView loadRequest:req];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    _webView.scrollView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
    _webView.scrollView.scrollIndicatorInsets = _webView.scrollView.contentInset;
    //_webView.scrollView.contentOffset = CGPointMake(0, 64);
    [_webView.scrollView scrollRectToVisible:CGRectMake(0, 64, 1, 1) animated:YES];
}

- (void)close {
    [self dismissViewControllerAnimated:YES completion:^{
        [kAppDelegate setOpenFile:nil];
    }];
}

- (void)showActionSheet:(id)sender {
    
    BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    
    if (_popupQuery && iPad) {
        [_popupQuery dismissWithClickedButtonIndex:_popupQuery.cancelButtonIndex animated:YES];
        self.popupQuery = nil;
        return;
    }
    
    self.popupQuery = [[UIActionSheet alloc]initWithTitle:[NSString stringWithFormat:@"What would you like to do with %@?",[kAppDelegate openFile].lastPathComponent] completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
        if (buttonIndex == 0) {
            [kAppDelegate printFile:[kAppDelegate openFile] fromView:self.view];
        } else if (buttonIndex == 1) {
            [kAppDelegate sendFileInEmail:[kAppDelegate openFile]];
        } else if (buttonIndex == 2) {
            BluetoothTask *task = [BluetoothTask taskWithFile:[kAppDelegate openFile]];
            [[TaskController sharedController]addTask:task];
        } else if (buttonIndex == 3) {
            DropboxUpload *task = [DropboxUpload uploadWithFile:[kAppDelegate openFile]];
            [[TaskController sharedController]addTask:task];
        }
    } cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Print", @"Email File", @"Send Via Bluetooth", @"Upload to Dropbox", nil];
    
    _popupQuery.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    
    if (iPad) {
        [_popupQuery showFromBarButtonItem:(UIBarButtonItem *)sender animated:YES];
    } else {
        [_popupQuery showInView:self.view];
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [_webView setNeedsDisplay];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

@end
