//
//  MyFilesViewDetailViewController.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 8/11/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import "MyFilesViewDetailViewController.h"

@implementation MyFilesViewDetailViewController

@synthesize webView, popupQuery;

- (void)loadView {
    [super loadView];
    self.view.backgroundColor = [UIColor clearColor];
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    UINavigationBar *bar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)];
    bar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:[[kAppDelegate openFile]lastPathComponent]];
    topItem.leftBarButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)]autorelease];
    topItem.rightBarButtonItem = [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showActionSheet:)]autorelease];
    [bar pushNavigationItem:topItem animated:NO];
    [self.view addSubview:bar];
    [self.view bringSubviewToFront:bar];
    [bar release];
    [topItem release];
    
    CGRect frame = CGRectMake(0, 44, screenBounds.size.width, screenBounds.size.height-44);
    self.webView = [[[UIWebView alloc]initWithFrame:frame]autorelease];
    self.webView.delegate = self;
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.backgroundColor = [UIColor clearColor];
    self.webView.contentMode = UIViewContentModeScaleAspectFit;
    self.webView.scalesPageToFit = YES;
    self.webView.dataDetectorTypes = UIDataDetectorTypeLink;
    
    [self.view addSubview:self.webView];
    [self.view bringSubviewToFront:self.webView];

    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:[kAppDelegate openFile]] cachePolicy:NSURLCacheStorageAllowed timeoutInterval:60.0];
    [self.webView loadRequest:req];
}

- (void)uploadToDropbox {
    if (![[DBSession sharedSession]isLinked]) {
        [[DBSession sharedSession]linkFromController:self];
    } else {
        [kAppDelegate uploadLocalFile:[kAppDelegate openFile]];
    }
}

- (void)close {
    [self dismissModalViewControllerAnimated:YES];
    [kAppDelegate setOpenFile:nil];
}

- (void)showActionSheet:(id)sender {
    if (self.popupQuery && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.popupQuery dismissWithClickedButtonIndex:self.popupQuery.cancelButtonIndex animated:YES];
        self.popupQuery = nil;
        return;
    }
    
    NSString *file = [kAppDelegate openFile];
    NSString *fileName = [file lastPathComponent];
    
    self.popupQuery = [[[UIActionSheet alloc]initWithTitle:[NSString stringWithFormat:@"What would you like to do with %@?",fileName] completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
        
        if (buttonIndex == 0) {
            [kAppDelegate printFile:file fromView:self.view];
        } else if (buttonIndex == 1) {
            [kAppDelegate sendFileInEmail:file fromViewController:self];
        } else if (buttonIndex == 2) {
            [kAppDelegate showBTController];
        } else if (buttonIndex == 3) {
            [kAppDelegate showFTPUploadController];
        } else if (buttonIndex == 4) {
            [self uploadToDropbox];
        }
        
    } cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Print", @"Email File", @"Send Via Bluetooth", @"Upload to Server", @"Upload to Dropbox", nil]autorelease];
    
    self.popupQuery.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.popupQuery showFromBarButtonItem:(UIBarButtonItem *)sender animated:YES];
    } else {
        [self.popupQuery showInView:self.view];
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self.webView setNeedsDisplay];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (void)dealloc {
    [self setWebView:nil];
    [self setPopupQuery:nil];
    NSLog(@"%@ dealloc'd", NSStringFromClass([self class]));
    [super dealloc];
}

@end
