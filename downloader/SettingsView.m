//
//  SettingsView.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/6/12.
//  Copyright 2012 Nathaniel Symer. All rights reserved.
//

#import "SettingsView.h"

@implementation SettingsView

- (void)loadView {
    [super loadView];
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    
    self.view = [StyleFactory backgroundImageView];
    
    UINavigationBar *bar = [[ShadowedNavBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)];
    bar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"Settings"];
    topItem.leftBarButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)]autorelease];
    [bar pushNavigationItem:topItem animated:NO];
    [self.view addSubview:bar];
    [bar release];
    [topItem release];
    
    BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    
    self.linkButton = [UIButton customizedButton];
    _linkButton.frame = CGRectMake(iPad?313:88, iPad?396:sanitizeMesurement(189), 143, 37);
    [_linkButton addTarget:self action:@selector(linkOrUnlink) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_linkButton];
    
    UIButton *bookmarkletButton = [UIButton customizedButton];
    bookmarkletButton.frame = CGRectMake(iPad?302:75, iPad?483:sanitizeMesurement(265), 170, 37);
    [bookmarkletButton addTarget:self action:@selector(showBookmarkletInstallationAV) forControlEvents:UIControlEventTouchUpInside];
    [bookmarkletButton setTitle:@"Install Bookmarklet" forState:UIControlStateNormal];
    [self.view addSubview:bookmarkletButton];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(dropboxAuthenticationSucceeded) name:@"db_auth_success" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(dropboxAuthenticationFailed) name:@"db_auth_failure" object:nil];
}

- (void)close {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)showBookmarkletInstallationAV {
    TransparentAlert *cav = [[TransparentAlert alloc]initWithTitle:@"Install Bookmarklet?" message:@"This bookmarklet allows you to download any file open in Safari. Clicking \"Sure!\" will overwrite your clipboard's content." completionBlock:^(NSUInteger buttonIndex, UIAlertView *alertView) {
        
        if (buttonIndex == 1) {
            [[UIPasteboard generalPasteboard]setString:@"JavaScript:string=document.URL;anotherString=string.replace('http://','swiftload://');window.open(anotherString);"];
            TransparentAlert *av = [[TransparentAlert alloc]initWithTitle:@"Bookmarklet Copied!" message:@"Open Safari and create a bookmark, naming it \"SwiftLoad Download\". Enter editing mode in the bookmarks menu and tap the newly created bookmark. Paste the contents of the clipboard to the URL field of the newly created bookmark, replacing whatever is already there. Tap done then exit editing mode. To download files, just navigate to a page and tap the bookmark." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [av show];
            [av release];
        }
        
    } cancelButtonTitle:@"Nah..." otherButtonTitles:@"Sure!",nil];
    [cav show];
    [cav release];
}

- (void)sessionDidReceiveAuthorizationFailure:(DBSession *)session userId:(NSString *)userId {
    [[[[TransparentAlert alloc]initWithTitle:@"Login Failed" message:@"There was an error in trying to log into Dropbox. Please try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]autorelease]show];
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
    [self setLinkButton:nil];
    NSLog(@"%@ dealloc'd", NSStringFromClass([self class]));
    [super dealloc];
}

@end
