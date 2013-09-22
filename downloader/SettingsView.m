//
//  SettingsView.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/6/12.
//  Copyright 2012 Nathaniel Symer. All rights reserved.
//

#import "SettingsView.h"

static NSString * const kJavaScriptBookmarklet = @"JavaScript:window.open(document.URL.replace('http://','swift://'));";
static NSString * const kSettingsTableViewCellID = @"settingsTableViewCellIdentifier";

@interface SettingsView () <DBSessionDelegate, DBRestClientDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *theTableView;

@end

@implementation SettingsView

- (void)loadView {
    [super loadView];
    CGRect screenBounds = [[UIScreen mainScreen]bounds];

    self.theTableView = [[UITableView alloc]initWithFrame:screenBounds style:UITableViewStyleGrouped];
    _theTableView.delegate = self;
    _theTableView.dataSource = self;
    _theTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    _theTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _theTableView.rowHeight = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)?60:44;
    _theTableView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
    _theTableView.scrollIndicatorInsets = _theTableView.contentInset;
    [self.view addSubview:_theTableView];
    
    UINavigationBar *bar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 64)];
    bar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"Settings"];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    [bar pushNavigationItem:topItem animated:NO];
    [self.view addSubview:bar];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(dropboxAuthenticationSucceeded) name:@"db_auth_success" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(dropboxAuthenticationFailed) name:@"db_auth_failure" object:nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kSettingsTableViewCellID];
    
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kSettingsTableViewCellID];
    }
    
    if (indexPath.row == 0) {
        cell.textLabel.text = [[DBSession sharedSession]isLinked]?@"Unlink Dropbox":@"Link Dropbox";
    } else if (indexPath.row == 1) {
        cell.textLabel.text = @"Install Bookmarklet";
    } else if (indexPath.row == 2) {
        cell.textLabel.text = @"Setup WebDAV User";
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        if ([[DBSession sharedSession]isLinked]) {
            [[DBSession sharedSession]unlinkUserId:[[DBSession sharedSession]userIds][0]];
            [_theTableView reloadData];
            [DropboxBrowserViewController clearDatabase];
        } else {
            [[DBSession sharedSession]linkFromController:self];
        }

    } else if (indexPath.row == 1) {
        UIAlertView *cav = [[UIAlertView alloc]initWithTitle:@"Install Bookmarklet?" message:@"This bookmarklet allows you to download any file open in Safari. Clicking \"Sure!\" will overwrite your clipboard's content." completionBlock:^(NSUInteger buttonIndex, UIAlertView *alertView) {
            
            if (buttonIndex == 1) {
                [[UIPasteboard generalPasteboard]setString:kJavaScriptBookmarklet];
                [UIAlertView showAlertWithTitle:@"Bookmarklet Copied!" andMessage:@"Open Safari and create a bookmark, naming it \"Swift Download\". Open the bookmarks menu and enter editing mode. Tap the newly created bookmark and paste the contents of the clipboard to the URL field, replacing whatever is already there. Tap done then exit editing mode. To download files, just navigate to a page and tap the bookmark."];
            }
            
        } cancelButtonTitle:@"Nah..." otherButtonTitles:@"Sure!",nil];
        [cav show];
    } else if (indexPath.row == 2) {
        
        UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"WebDAV Account" message:@"Please enter a username and password to secure Swift's WebDAV server." completionBlock:^(NSUInteger buttonIndex, UIAlertView *alertView) {
            if (buttonIndex == 1) {
                [SimpleKeychain save:@"webdav_creds" data:@{@"username": [alertView textFieldAtIndex:0].text, @"password": [alertView textFieldAtIndex:1].text}];
            }
        } cancelButtonTitle:@"Cancel" otherButtonTitles:@"Save", nil];
        av.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
        
        NSDictionary *creds = [SimpleKeychain load:@"webdav_creds"];
        
        UITextField *tv = [av textFieldAtIndex:0];
        tv.returnKeyType = UIReturnKeyDone;
        tv.autocapitalizationType = UITextAutocapitalizationTypeNone;
        tv.autocorrectionType = UITextAutocorrectionTypeNo;
        tv.placeholder = @"Username";
        tv.clearButtonMode = UITextFieldViewModeWhileEditing;
        tv.text = creds[@"username"];
        
        UITextField *pass = [av textFieldAtIndex:1];
        pass.returnKeyType = UIReturnKeyDone;
        pass.autocapitalizationType = UITextAutocapitalizationTypeNone;
        pass.autocorrectionType = UITextAutocorrectionTypeNo;
        pass.placeholder = @"Password";
        pass.clearButtonMode = UITextFieldViewModeWhileEditing;
        pass.text = creds[@"password"];
        
        [av show];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)close {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)sessionDidReceiveAuthorizationFailure:(DBSession *)session userId:(NSString *)userId {
    [_theTableView reloadData];
    [UIAlertView showAlertWithTitle:@"Dropbox Login Failed" andMessage:@"There was an error in trying to log into Dropbox. Please try again later."];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [_theTableView reloadData];
}

- (void)dropboxAuthenticationFailed {
    [_theTableView reloadData];
}

- (void)dropboxAuthenticationSucceeded {
    [_theTableView reloadData];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end
