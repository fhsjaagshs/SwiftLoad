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
    
    self.webView = [[UIWebView alloc]initWithFrame:CGRectMake(0, 64, screenBounds.size.width, screenBounds.size.height-64)];
    _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _webView.backgroundColor = [UIColor clearColor];
    _webView.contentMode = UIViewContentModeScaleAspectFit;
    _webView.scalesPageToFit = YES;
    _webView.dataDetectorTypes = UIDataDetectorTypeLink;
    _webView.layer.rasterizationScale = [[UIScreen mainScreen]scale];
    _webView.layer.shouldRasterize = YES;
    _webView.scrollView.clipsToBounds = NO;
    [self.view addSubview:_webView];
    
    UINavigationBar *bar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 64)];
    bar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:kAppDelegate.openFile.lastPathComponent];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showActionSheet:)];
    [bar pushNavigationItem:topItem animated:NO];
    [self.view addSubview:bar];

    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:kAppDelegate.openFile] cachePolicy:NSURLCacheStorageAllowedInMemoryOnly timeoutInterval:30.0f];
    [_webView loadRequest:req];
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
    
    self.popupQuery = [[UIActionSheet alloc]initWithTitle:[NSString stringWithFormat:@"What would you like to do with %@?",kAppDelegate.openFile.lastPathComponent] completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
        NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
        
        if ([title isEqualToString:kActionButtonNameEmail]) {
            [kAppDelegate sendFileInEmail:kAppDelegate.openFile];
        } else if ([title isEqualToString:kActionButtonNameP2P]) {
            [[BTManager shared]sendFileAtPath:kAppDelegate.openFile];
        } else if ([title isEqualToString:kActionButtonNameDBUpload]) {
            [[TaskController sharedController]addTask:[DropboxUpload uploadWithFile:kAppDelegate.openFile]];
        } else if ([title isEqualToString:kActionButtonNamePrint]) {
            [kAppDelegate printFile:kAppDelegate.openFile];
        }
    } cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:kActionButtonNameEmail, kActionButtonNameP2P, kActionButtonNameDBUpload, nil];
    
    if ([kAppDelegate.openFile isDocumentFile] || [kAppDelegate.openFile isImageFile]) {
        [_popupQuery addButtonWithTitle:kActionButtonNamePrint];
    }
    
    [_popupQuery addButtonWithTitle:@"Cancel"];
    _popupQuery.cancelButtonIndex = _popupQuery.numberOfButtons-1;
    
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
