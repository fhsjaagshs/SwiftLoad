//
//  FTPBrowserViewController.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 3/27/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "FTPBrowserViewController.h"
#import "ButtonBarView.h"
#import "CustomCellCell.h"

@interface FTPBrowserViewController ()

@property (nonatomic, retain) ShadowedTableView *theTableView;
@property (nonatomic, retain) CustomButton *backButton;
@property (nonatomic, retain) CustomButton *homeButton;
@property (nonatomic, retain) UINavigationBar *navBar;
@property (nonatomic, retain) PullToRefreshView *pull;

@property (nonatomic, retain) NSString *currentFTPURL;
@property (nonatomic, retain) NSString *originalFTPURL;
@property (nonatomic, retain) NSMutableArray *filedicts;

@end

@implementation FTPBrowserViewController

@synthesize theTableView, backButton, homeButton, navBar, pull, currentFTPURL, originalFTPURL, filedicts;

- (void)loadView {
    [super loadView];
    
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    
    self.view = [StyleFactory backgroundImageView];

    self.navBar = [[[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)]autorelease];
    self.navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[[UINavigationItem alloc]initWithTitle:@"/"]autorelease];
    topItem.rightBarButtonItem = nil;
    topItem.leftBarButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)]autorelease];
    [self.navBar pushNavigationItem:topItem animated:YES];
    [self.view addSubview:self.navBar];
    
    UIImageView *bbv = [StyleFactory buttonBarImageView];
    bbv.frame = CGRectMake(0, 44, screenBounds.size.width, 44);
    [self.view addSubview:bbv];
    
    self.homeButton = [[[CustomButton alloc]initWithFrame:iPad?CGRectMake(358, 4, 62, 36):CGRectMake(123, 4, 62, 36)]autorelease];
    [self.homeButton setTitle:@"Home" forState:UIControlStateNormal];
    [self.homeButton addTarget:self action:@selector(goHome) forControlEvents:UIControlEventTouchUpInside];
    self.homeButton.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    self.homeButton.titleLabel.shadowColor = [UIColor blackColor];
    self.homeButton.titleLabel.shadowOffset = CGSizeMake(0, -1);
    self.homeButton.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    [bbv addSubview:self.homeButton];
    [self.homeButton setHidden:YES];
    
    self.backButton = [[[CustomButton alloc]initWithFrame:iPad?CGRectMake(117, 4, 62, 36):CGRectMake(53, 4, 62, 37)]autorelease];
    [self.backButton setTitle:@"Back" forState:UIControlStateNormal];
    [self.backButton addTarget:self action:@selector(goBackDir) forControlEvents:UIControlEventTouchUpInside];
    self.backButton.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    self.backButton.titleLabel.shadowColor = [UIColor blackColor];
    self.backButton.titleLabel.shadowOffset = CGSizeMake(0, -1);
    self.backButton.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    [bbv addSubview:self.backButton];
    [self.backButton setHidden:YES];
    
    self.theTableView = [[[ShadowedTableView alloc]initWithFrame:CGRectMake(0, 88, screenBounds.size.width, screenBounds.size.height-88) style:UITableViewStylePlain]autorelease];
    self.theTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.theTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.theTableView.backgroundColor = [UIColor clearColor];
    self.theTableView.rowHeight = iPad?60:44;
    self.theTableView.dataSource = self;
    self.theTableView.delegate = self;
    [self.view addSubview:self.theTableView];
    
    self.pull = [[[PullToRefreshView alloc]initWithScrollView:self.theTableView]autorelease];
    [self.pull setDelegate:self];
    [self.theTableView addSubview:self.pull];
    
    [self showInitialLoginController];
}

- (NSString *)fixURL:(NSString *)url {
    NSString *lastChar = [url substringFromIndex:url.length-1];
    if (![lastChar isEqualToString:@"/"]) {
        return [url stringByAppendingString:@"/"];
    }
    return url;
}

- (void)showInitialLoginController {
    
    NSString *browserURL = [[NSUserDefaults standardUserDefaults]objectForKey:@"FTPURLBrowser"];
    
    FTPLoginController *controller = [[[FTPLoginController alloc]initWithCompletionHandler:^(NSString *username, NSString *password, NSString *url) {
        if ([username isEqualToString:@"cancel"]) {
            [self dismissModalViewControllerAnimated:YES];
        } else {
            self.currentFTPURL = [self fixURL:url];
            NSLog(@"URL: %@",url);
            self.originalFTPURL = [self fixURL:url];
            [[NSUserDefaults standardUserDefaults]setObject:self.originalFTPURL forKey:@"FTPURLBrowser"];
            [self saveUsername:username andPassword:password forURL:[NSURL URLWithString:self.currentFTPURL]];
            [self sendReqestForCurrentURL];
        }
    }]autorelease];
    [controller setType:FTPLoginControllerTypeLogin];
    controller.textFieldDelegate = self;
    controller.didMoveOnSelector = @selector(didMoveOn);
    
    if (browserURL.length > 0) {
        [controller setUrl:browserURL isPredefined:NO];
    }
    
    [controller show];
}

- (void)didMoveOn:(FTPLoginController *)controller {
    NSString *url = nil;
    for (UIView *view in controller.subviews) {
        if ([view isKindOfClass:[UITextField class]]) {
            UITextField *tf = (UITextField *)view;
            if ([tf.placeholder isEqualToString:@"ftp://"]) {
                url = tf.text;
            }
        }
    }
    
    if (url.length > 0) {
        NSDictionary *creds = [self getCredsForURL:[NSURL URLWithString:url]];
        
        if (creds) {
            NSString *username = [creds objectForKey:@"username"];
            NSString *password = [creds objectForKey:@"password"];
            
            for (UIView *view in controller.subviews) {
                if ([view isKindOfClass:[UITextField class]]) {
                    UITextField *tf = (UITextField *)view;
                    if ([tf.placeholder isEqualToString:@"Username"]) {
                        tf.text = username;
                    } else if ([tf.placeholder isEqualToString:@"Password"]) {
                        tf.text = password;
                    }
                }
            }
        }
    }
}

- (void)close {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)removeCredsForURL:(NSURL *)ftpurl {
    KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc]initWithIdentifier:@"SwiftLoadFTPCreds" accessGroup:nil];
    NSString *keychainData = (NSString *)[keychain objectForKey:(id)kSecValueData];
    
    int index = -1;
    
   NSMutableArray *triples = [NSMutableArray arrayWithArray:[keychainData componentsSeparatedByString:@","]];
    
    for (NSString *string in triples) {
        NSArray *components = [keychainData componentsSeparatedByString:@":"];
        NSString *host = [components objectAtIndex:2];
        if ([host isEqualToString:ftpurl.host]) {
            index = [triples indexOfObject:string];
            break;
        }
    }
    
    [triples removeObjectAtIndex:index];
    NSString *final = [triples componentsJoinedByString:@","];
    [keychain setObject:final forKey:(id)kSecValueData];
    
    [keychain release];
}

- (void)saveUsername:(NSString *)username andPassword:(NSString *)password forURL:(NSURL *)ftpurl {
    
    KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc]initWithIdentifier:@"SwiftLoadFTPCreds" accessGroup:nil];
    NSString *keychainData = (NSString *)[keychain objectForKey:(id)kSecValueData];
    int index = -1;
    
    NSMutableArray *triples = [NSMutableArray arrayWithArray:[keychainData componentsSeparatedByString:@","]];
    
    for (NSString *string in [[triples mutableCopy]autorelease]) {
        
        if (string.length == 0) {
            [triples removeObject:string];
            continue;
        }
        
        NSArray *components = [string componentsSeparatedByString:@":"];
        
        NSString *host = [components objectAtIndex:2];
        if ([host isEqualToString:ftpurl.host]) {
            index = [triples indexOfObject:string];
            break;
        }
    }
    
    if (password.length == 0) {
        password = @" ";
    }
    
    if (index == -1) {
        NSString *concatString = [NSString stringWithFormat:@"%@:%@:%@",username, password, ftpurl.host];
        [triples addObject:concatString];
    } else {
        NSString *concatString = [NSString stringWithFormat:@"%@:%@:%@",username, password, ftpurl.host];
        [triples replaceObjectAtIndex:index withObject:concatString];
    }
    
    NSString *final = [triples componentsJoinedByString:@","];
    
    [keychain setObject:final forKey:(id)kSecValueData];
    [keychain release];
}

- (NSDictionary *)getCredsForURL:(NSURL *)ftpurl {
    KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc]initWithIdentifier:@"SwiftLoadFTPCreds" accessGroup:nil];    
    NSString *keychainData = (NSString *)[keychain objectForKey:(id)kSecValueData];
    [keychain release];
    
    if (keychainData.length == 0) {
        return nil;
    }
    
    // username:password:host, username:password:host, username:password:host
    
    NSString *username = nil;
    NSString *password = nil;
    
    NSArray *triples = [keychainData componentsSeparatedByString:@","];
    
    for (NSString *string in triples) {
        
        NSArray *components = [string componentsSeparatedByString:@":"];
        
        if (components.count == 0) {
            continue;
        }
        
        NSString *host = [components objectAtIndex:2];
        
        if ([host isEqualToString:ftpurl.host]) {
            username = [components objectAtIndex:0];
            password = [components objectAtIndex:1];
            break;
        }
    }
    
    if (username.length > 0 && password.length > 0) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setObject:username forKey:@"username"];
        [dict setObject:password forKey:@"password"];
        return dict;
    }
    return nil;
}

- (void)listFinished:(SCRFTPRequest *)request {
    self.filedicts = [NSMutableArray arrayWithArray:request.directoryContents];
    [self cacheCurrentDir];
    [self.theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    [self.pull finishedLoading];
    [request release];
}

- (void)listFailed:(SCRFTPRequest *)request {
    CustomAlertView *av = [[CustomAlertView alloc]initWithTitle:@"FTP Error" message:request.error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [av show];
    [av release];
    
    [self.theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    [self.pull finishedLoading];
    [request release];
}

- (void)sendReqestForCurrentURL {
    NSDictionary *creds = [self getCredsForURL:[NSURL URLWithString:self.currentFTPURL]];
    NSString *username = [creds objectForKey:@"username"];
    NSString *password = [creds objectForKey:@"password"];
    SCRFTPRequest *ftpRequest = [[SCRFTPRequest requestWithURLToListDirectory:[NSURL URLWithString:self.currentFTPURL]]retain];
    ftpRequest.username = username;
    ftpRequest.password = password;
    ftpRequest.delegate = self;
    ftpRequest.didFinishSelector = @selector(listFinished:);
    ftpRequest.didFailSelector = @selector(listFailed:);
    [ftpRequest startRequest];
    [self.pull setState:PullToRefreshViewStateLoading];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filedicts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    CustomCellCell *cell = (CustomCellCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[[CustomCellCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier]autorelease];
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            cell.textLabel.font = [UIFont fontWithName:@"MarkerFelt-Thin" size:27];
            cell.detailTextLabel.font = [UIFont systemFontOfSize:20.0];
        } else {
            cell.textLabel.font = [UIFont fontWithName:@"MarkerFelt-Thin" size:20];
        }
    }
    
    NSDictionary *fileDict = [self.filedicts objectAtIndex:indexPath.row];
    NSString *filename = [fileDict objectForKey:NSFileName];
    
    cell.textLabel.text = filename;
    
    if ([(NSString *)[fileDict objectForKey:NSFileType] isEqualToString:(NSString *)NSFileTypeRegular]) {
        float fileSize = [[fileDict objectForKey:NSFileSize]intValue];
        
        cell.detailTextLabel.text = @"File, ";
        
        if (fileSize < 1024.0) {
            cell.detailTextLabel.text = [cell.detailTextLabel.text stringByAppendingFormat:@"%.0f Byte%@",fileSize,(fileSize > 1)?@"s":@""];
        } else if (fileSize < (1024*1024) && fileSize > 1024.0 ) {
            fileSize = fileSize/1014;
            cell.detailTextLabel.text = [cell.detailTextLabel.text stringByAppendingFormat:@"%.0f KB",fileSize];
        } else if (fileSize < (1024*1024*1024) && fileSize > (1024*1024)) {
            fileSize = fileSize/(1024*1024);
            cell.detailTextLabel.text = [cell.detailTextLabel.text stringByAppendingFormat:@"%.0f MB",fileSize];
        }
    } else {
        cell.detailTextLabel.text = @"Directory";
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary *fileDict = [self.filedicts objectAtIndex:indexPath.row];
    NSString *filename = [fileDict objectForKey:NSFileName];
    
    NSString *filetype = (NSString *)[fileDict objectForKey:NSFileType];
    
    if ([filetype isEqualToString:(NSString *)NSFileTypeDirectory]) {
        self.currentFTPURL = [self fixURL:[self.currentFTPURL stringByAppendingPathComponent_URLSafe:filename]];
        self.navBar.topItem.title = [self.navBar.topItem.title stringByAppendingPathComponent:filename];
        [self loadCurrentDirectory];
        if (self.currentFTPURL.length > self.originalFTPURL.length) {
            [self setButtonsHidden:NO];
        }
    } else if ([filetype isEqualToString:(NSString *)NSFileTypeRegular]) {
        NSString *message = [NSString stringWithFormat:@"Do you wish to download \"%@\"?",filename];
        UIActionSheet *actionSheet = [[[UIActionSheet alloc]initWithTitle:message completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
            if (buttonIndex == 0) {
                NSDictionary *creds = [self getCredsForURL:[NSURL URLWithString:[self fixURL:self.currentFTPURL]]];
                [kAppDelegate downloadFileUsingFtp:[self.currentFTPURL stringByAppendingPathComponent_URLSafe:filename] withUsername:[creds objectForKey:@"username"] andPassword:[creds objectForKey:@"password"]];
            }
        } cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Download", nil]autorelease];
        actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        [actionSheet showInView:self.view];
    } else {
        NSString *message = [NSString stringWithFormat:@"What do you wish to do with \"%@\"?",filename];
        UIActionSheet *actionSheet = [[[UIActionSheet alloc]initWithTitle:message completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
            if (buttonIndex == 0) {
                NSDictionary *creds = [self getCredsForURL:[NSURL URLWithString:[self fixURL:self.currentFTPURL]]];
                [kAppDelegate downloadFileUsingFtp:[self.currentFTPURL stringByAppendingPathComponent_URLSafe:filename] withUsername:[creds objectForKey:@"username"] andPassword:[creds objectForKey:@"password"]];
            } else if (buttonIndex == 1) {
                self.currentFTPURL = [self fixURL:[self.currentFTPURL stringByAppendingPathComponent_URLSafe:filename]];
                self.navBar.topItem.title = [self.navBar.topItem.title stringByAppendingPathComponent:filename];
                [self loadCurrentDirectory];
                if (self.currentFTPURL.length > self.originalFTPURL.length) {
                    [self setButtonsHidden:NO];
                }
            }
        } cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Download", @"Treat as Directory", nil]autorelease];
        actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        [actionSheet showInView:self.view];
    }
    
    [self.theTableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view {
    [self sendReqestForCurrentURL];
}

- (void)cacheCurrentDir {
    NSString *cachePath = [kCachesDir stringByAppendingPathComponent:@"cachedFTPDirs.plist"];
    NSMutableDictionary *savedDict = [NSMutableDictionary dictionaryWithContentsOfFile:cachePath];
    
    if (savedDict.count == 0) {
        savedDict = [NSMutableDictionary dictionary];
    }
    
    [savedDict setObject:self.filedicts forKey:[self fixURL:self.currentFTPURL]];
    [savedDict writeToFile:cachePath atomically:YES];
}

- (void)loadDirFromCacheForURL:(NSString *)url {
    NSString *cachePath = [kCachesDir stringByAppendingPathComponent:@"cachedFTPDirs.plist"];
    NSMutableDictionary *savedDict = [NSMutableDictionary dictionaryWithContentsOfFile:cachePath];
    self.filedicts = [NSMutableArray arrayWithArray:[savedDict objectForKey:url]];
}

- (void)loadCurrentDirectory {
    NSString *cachePath = [kCachesDir stringByAppendingPathComponent:@"cachedFTPDirs.plist"];
    NSMutableDictionary *savedDict = [NSMutableDictionary dictionaryWithContentsOfFile:cachePath];
    
    if ([savedDict objectForKey:[self fixURL:self.currentFTPURL]]) {
        self.filedicts = [NSMutableArray arrayWithArray:[savedDict objectForKey:[self fixURL:self.currentFTPURL]]];
        [self.theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        [self.pull finishedLoading];
    } else {
        [self sendReqestForCurrentURL];
    }
}

- (void)setButtonsHidden:(BOOL)shouldHide {
    [self.backButton setHidden:shouldHide];
    [self.homeButton setHidden:shouldHide];
}

- (void)goHome {
    self.currentFTPURL = [self fixURL:self.originalFTPURL];
    self.navBar.topItem.title = @"/";
    [self loadCurrentDirectory];
    [self setButtonsHidden:YES];
}

- (void)goBackDir {
    if (self.currentFTPURL.length > self.originalFTPURL.length) {
        self.currentFTPURL = [self fixURL:[self.currentFTPURL stringByDeletingLastPathComponent_URLSafe]];
        self.navBar.topItem.title = [self.navBar.topItem.title stringByDeletingLastPathComponent];
        [self loadCurrentDirectory];
        
        if (self.currentFTPURL.length <= self.originalFTPURL.length) {
            [self setButtonsHidden:YES];
        }
    } 
}

- (void)dealloc {
    [self setBackButton:nil];
    [self setHomeButton:nil];
    [self setNavBar:nil];
    [self setCurrentFTPURL:nil];
    [self setFiledicts:nil];
    [self setOriginalFTPURL:nil];
    [self setTheTableView:nil];
    NSLog(@"%@ dealloc'd", NSStringFromClass([self class]));
    [super dealloc];
}

@end
