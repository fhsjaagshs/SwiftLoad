//
//  SettingsView.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/6/12.
//  Copyright 2012 Nathaniel Symer. All rights reserved.
//

#import "SettingsView.h"

static NSString * const kJavaScriptBookmarklet = @"JavaScript:window.open(document.URL.replace('http://','swift://'));";

@implementation SettingsView

- (void)loadView {
    [super loadView];
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    
    self.view = [StyleFactory backgroundView];
    
    UINavigationBar *bar = [[ShadowedNavBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)];
    bar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"Settings"];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    [bar pushNavigationItem:topItem animated:NO];
    [self.view addSubview:bar];
    
    BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    
    self.linkButton = [UIButton customizedButton];
    _linkButton.frame = CGRectMake((self.view.bounds.size.width/2)-1, iPad?396:sanitizeMesurement(189), 2, 37);
    [_linkButton addTarget:self action:@selector(linkOrUnlink) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_linkButton];
    
    UIButton *bookmarkletButton = [UIButton customizedButton];
    bookmarkletButton.frame = CGRectMake((self.view.bounds.size.width/2)-1, iPad?483:sanitizeMesurement(265), 2, 37);
    [bookmarkletButton addTarget:self action:@selector(showBookmarkletInstallationAV) forControlEvents:UIControlEventTouchUpInside];
    [bookmarkletButton setTitle:@"Install Bookmarklet" forState:UIControlStateNormal];
    [self.view addSubview:bookmarkletButton];
    [bookmarkletButton resizeForTitle];
    
    UIButton *setCredsButton = [UIButton customizedButton];
    setCredsButton.frame = CGRectMake((self.view.bounds.size.width/2)-1, self.view.bounds.size.height-37-10, 2, 37);
    [setCredsButton setTitle:@"Set WebDAV User" forState:UIControlStateNormal];
    [setCredsButton addTarget:self action:@selector(showCredsController) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:setCredsButton];
    [setCredsButton resizeForTitle];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(dropboxAuthenticationSucceeded) name:@"db_auth_success" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(dropboxAuthenticationFailed) name:@"db_auth_failure" object:nil];
}

- (void)showCredsController {
    [[[WebDAVCredsPrompt alloc]initWithCredsDelegate:nil]show];
}

- (void)close {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)showBookmarkletInstallationAV {
    TransparentAlert *cav = [[TransparentAlert alloc]initWithTitle:@"Install Bookmarklet?" message:@"This bookmarklet allows you to download any file open in Safari. Clicking \"Sure!\" will overwrite your clipboard's content." completionBlock:^(NSUInteger buttonIndex, UIAlertView *alertView) {
        
        if (buttonIndex == 1) {
            [[UIPasteboard generalPasteboard]setString:kJavaScriptBookmarklet];
            TransparentAlert *av = [[TransparentAlert alloc]initWithTitle:@"Bookmarklet Copied!" message:@"Open Safari and create a bookmark, naming it \"Swift Download\". Open the bookmarks menu and enter editing mode. Tap the newly created bookmark and paste the contents of the clipboard to the URL field, replacing whatever is already there. Tap done then exit editing mode. To download files, just navigate to a page and tap the bookmark." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [av show];
        }
        
    } cancelButtonTitle:@"Nah..." otherButtonTitles:@"Sure!",nil];
    [cav show];
}

- (void)sessionDidReceiveAuthorizationFailure:(DBSession *)session userId:(NSString *)userId {
    [[[TransparentAlert alloc]initWithTitle:@"Login Failed" message:@"There was an error in trying to log into Dropbox. Please try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]show];
}

- (void)linkOrUnlink {
    if ([[DBSession sharedSession]isLinked]) {
        [[DBSession sharedSession]unlinkUserId:[[[DBSession sharedSession]userIds]objectAtIndex:0]];
        [_linkButton setTitle:@"Link Dropbox" forState:UIControlStateNormal];
        [_linkButton resizeForTitle];
        [DropboxBrowserViewController clearDatabase];
    } else {
        [[DBSession sharedSession]linkFromController:self];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [_linkButton setTitle:[[DBSession sharedSession]isLinked]?@"Unlink Dropbox":@"Link Dropbox" forState:UIControlStateNormal];
}

- (void)dropboxAuthenticationFailed {
    [self.linkButton setTitle:@"Link Dropbox" forState:UIControlStateNormal];
    [_linkButton resizeForTitle];
}

- (void)dropboxAuthenticationSucceeded {
    [self.linkButton setTitle:@"Unlink Dropbox" forState:UIControlStateNormal];
    [_linkButton resizeForTitle];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end
