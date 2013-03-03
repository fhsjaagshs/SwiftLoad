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
    CustomNavBar *bar = [[CustomNavBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)];
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

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)showActionSheet:(id)sender {
    NSString *file = [kAppDelegate openFile];
    NSString *fileName = [file lastPathComponent];
    NSString *message = [[NSString alloc]initWithFormat:@"What would you like to do with %@?",fileName];
    
    UIActionSheet *sheet = [[UIActionSheet alloc]initWithTitle:message completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
        NSString *file = [kAppDelegate openFile];
        NSString *fileName = [file lastPathComponent];
        
        if (buttonIndex == 0) {
            if (![MFMailComposeViewController canSendMail]) {
                CustomAlertView *av = [[CustomAlertView alloc]initWithTitle:@"Mail Unavailable" message:@"In order to use this functionality, you must set up an email account in Settings." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [av show];
                [av release];
            } else {
                MFMailComposeViewController *controller = [[MFMailComposeViewController alloc]init];
                controller.mailComposeDelegate = self;
                [controller setSubject:@"Your file"];
                NSData *myData = [[NSData alloc]initWithContentsOfFile:file];
                [controller addAttachmentData:myData mimeType:[MIMEUtils fileMIMEType:file] fileName:fileName];
                [controller setMessageBody:@"" isHTML:NO];
                [self presentModalViewController:controller animated:YES];
                [controller release];
                [myData release];
            }
        } else if (buttonIndex == 1) {
            if ([MIMEUtils isTextFile:file] == NO) {
                NSString *title = [[NSString alloc]initWithFormat:@"Sorry, \"%@\" is not editable.", fileName];
                CustomAlertView *av = [[CustomAlertView alloc]initWithTitle:title message:@"Sorry, the file you have tried to edit is not editable in its current state." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [av show];
                [av release];
                [title release];
            } else {
                dedicatedTextEditor *textEditor = [[dedicatedTextEditor alloc]initWithAutoNib];
                textEditor.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                [self presentModalViewController:textEditor animated:YES];
                [textEditor release];
            }
        } else if (buttonIndex == 2) {
            [kAppDelegate printFile:file fromView:self.view];
        } else if (buttonIndex == 3) {
            [kAppDelegate showBTController];
        } else if (buttonIndex == 4) {
            [kAppDelegate showFTPUploadController];
        } else if (buttonIndex == 5) {
            [self uploadToDropbox];
        }
        
    } cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Email File", @"Add to Photo Library", @"Print", @"Send Via Bluetooth", @"Upload to Server", @"Upload to Dropbox", nil];
    
    [message release];
    
    [self setPopupQuery:sheet];
    [sheet release];
    
    self.popupQuery.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        
    if (!self.popupQuery.isVisible) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            [self.popupQuery showFromBarButtonItem:(UIBarButtonItem *)sender animated:YES];
        } else {
            [self.popupQuery showInView:self.view];
        }
    } else {
        [self.popupQuery dismissWithClickedButtonIndex:0 animated:YES];
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
