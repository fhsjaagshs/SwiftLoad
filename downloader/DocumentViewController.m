//
//  MyFilesViewDetailViewController.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 8/11/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import "DocumentViewController.h"

@interface DocumentViewController () <UIWebViewDelegate>

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) UINavigationBar *bar;

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
    
    self.bar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 64)];
    _bar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:self.openFile.lastPathComponent];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showActionSheet:)];
    [_bar pushNavigationItem:topItem animated:NO];
    [self.view addSubview:_bar];

    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:self.openFile] cachePolicy:NSURLCacheStorageAllowedInMemoryOnly timeoutInterval:30.0f];
    [_webView loadRequest:req];
}

- (void)close {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)actionSheet:(UIActionSheet *)actionSheet selectedIndex:(NSUInteger)buttonIndex {
    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if ([title isEqualToString:kActionButtonNameEmail]) {
        [kAppDelegate sendFileInEmail:self.openFile];
    } else if ([title isEqualToString:kActionButtonNameP2P]) {
        [[P2PManager shared]sendFileAtPath:self.openFile];
    } else if ([title isEqualToString:kActionButtonNameDBUpload]) {
        [[TaskController sharedController]addTask:[DropboxUpload uploadWithFile:self.openFile]];
    } else if ([title isEqualToString:kActionButtonNamePrint]) {
        [kAppDelegate printFile:self.openFile];
    }
}

- (void)showActionSheet:(id)sender {
    [self showActionSheetFromBarButtonItem:(UIBarButtonItem *)sender withButtonTitles:@[kActionButtonNameEmail, kActionButtonNameP2P, kActionButtonNameDBUpload]];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [_webView setNeedsDisplay];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

@end
