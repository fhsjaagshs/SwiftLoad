//
//  SettingsView.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/6/12.
//  Copyright 2012 Nathaniel Symer. All rights reserved.
//

#import "SettingsView.h"

@implementation SettingsView

@synthesize linkButton;

- (void)loadView {
    [super loadView];
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    
    self.view = [[StyleFactory sharedFactory]backgroundImageView]; // [[[HatchedView alloc]initWithFrame:screenBounds]autorelease];
    
    UINavigationBar *bar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)];
    bar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"Settings"];
    topItem.leftBarButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)]autorelease];
    [bar pushNavigationItem:topItem animated:NO];
    [self.view addSubview:bar];
    [self.view bringSubviewToFront:bar];
    [bar release];
    [topItem release];
    
    CGRect linkButtonFrame = CGRectMake(92, sanitizeMesurement(189), 136, 37);
    CGRect bmbFrame = CGRectMake(78, sanitizeMesurement(265), 164, 37);
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        linkButtonFrame = CGRectMake(313, 396, 143, 37);
        bmbFrame = CGRectMake(302, 483, 164, 37);
    }
    
    self.linkButton = [[[CustomButton alloc]initWithFrame:linkButtonFrame]autorelease];
    self.linkButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.linkButton addTarget:self action:@selector(linkOrUnlink) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.linkButton];
    [self.view bringSubviewToFront:self.linkButton];
    
    CustomButton *bookmarkletButton = [[CustomButton alloc]initWithFrame:bmbFrame];
    bookmarkletButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [bookmarkletButton addTarget:self action:@selector(linkOrUnlink) forControlEvents:UIControlEventTouchUpInside];
    [bookmarkletButton setTitle:@"Install Bookmarklet" forState:UIControlStateNormal];
    [self.view addSubview:bookmarkletButton];
    [self.view bringSubviewToFront:bookmarkletButton];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(dropboxAuthenticationSucceeded) name:@"db_auth_success" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(dropboxAuthenticationFailed) name:@"db_auth_failure" object:nil];
}

- (void)close {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)showBookmarkletInstallationAV {
    CustomAlertView *cav = [[CustomAlertView alloc]initWithTitle:@"Install Bookmarklet?" message:@"The bookmarklet allows you to download the open webpage or file from Safari.\n\nClicking \"sure\" will replace your clipboard's content." completionBlock:^(NSUInteger buttonIndex, UIAlertView *alertView) {
        
        if (buttonIndex == 1) {
            [[UIPasteboard generalPasteboard]setString:@"JavaScript:string=document.URL;anotherString=string.replace('http://','swiftload://');window.open(anotherString);"];
            CustomAlertView *av = [[CustomAlertView alloc]initWithTitle:@"Bookmarklet Copied!" message:@"Open Safari and create a bookmark, naming it \"SwiftLoad Download\". Enter editing mode in the bookmarks menu and tap the newly created bookmark. Paste the contents of the clipboard to the URL field of the newly created bookmark, replacing whatever is there. Tap done and exit editing mode. To download files, just navigate to a page and tap the bookmark." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [av show];
            [av release];
        }
        
    } cancelButtonTitle:@"Nah..." otherButtonTitles:@"Sure!",nil];
    [cav show];
    [cav release];
}

- (void)sessionDidReceiveAuthorizationFailure:(DBSession *)session userId:(NSString *)userId {
    CustomAlertView *asdf = [[[CustomAlertView alloc]initWithTitle:@"Login Failed" message:@"There was an error in trying to log into Dropbox. Please try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]autorelease];
    [asdf show];
}

- (void)linkOrUnlink {
    if ([[DBSession sharedSession]isLinked]) {
        [[DBSession sharedSession]unlinkUserId:[[[DBSession sharedSession]userIds]objectAtIndex:0]];
        [linkButton setTitle:@"Link Dropbox" forState:UIControlStateNormal];
    } else {
        [[DBSession sharedSession]linkFromController:self];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([[DBSession sharedSession]isLinked]) {
        [self.linkButton setTitle:@"Unlink Dropbox" forState:UIControlStateNormal];
    } else {
        [self.linkButton setTitle:@"Link Dropbox" forState:UIControlStateNormal];
    }
}

- (void)dropboxAuthenticationFailed {
    [self.linkButton setTitle:@"Link Dropbox" forState:UIControlStateNormal];
}

- (void)dropboxAuthenticationSucceeded {
    [self.linkButton setTitle:@"Unlink Dropbox" forState:UIControlStateNormal];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [self setLinkButton:nil];
    NSLog(@"%@ dealloc'd", NSStringFromClass([self class]));
    [super dealloc];
}

@end
