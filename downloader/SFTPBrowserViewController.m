//
//  SFTPBrowserViewController.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 7/5/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "SFTPBrowserViewController.h"
#import "CK2SFTPSession.h"

@interface SFTPBrowserViewController () <PullToRefreshViewDelegate, UITableViewDataSource, UITableViewDelegate, CK2SFTPSessionDelegate>

@property (nonatomic, retain) ShadowedTableView *theTableView;
@property (nonatomic, retain) UIButton *backButton;
@property (nonatomic, retain) UIButton *homeButton;
@property (nonatomic, retain) ShadowedNavBar *navBar;
@property (nonatomic, retain) PullToRefreshView *pull;
@property (nonatomic, retain) NSString *currentURL;
@property (nonatomic, retain) NSMutableArray *filedicts;

@property (nonatomic, retain) CK2SFTPSession *session;

@end

@implementation SFTPBrowserViewController

- (void)loadView {
    [super loadView];
    
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    
    self.view = [StyleFactory backgroundImageView];
    
    self.navBar = [[[ShadowedNavBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)]autorelease];
    self.navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[[UINavigationItem alloc]initWithTitle:@"/"]autorelease];
    topItem.rightBarButtonItem = nil;
    topItem.leftBarButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)]autorelease];
    [self.navBar pushNavigationItem:topItem animated:YES];
    [self.view addSubview:self.navBar];
    
    UIImageView *bbv = [StyleFactory buttonBarImageView];
    bbv.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    bbv.frame = CGRectMake(0, 44, screenBounds.size.width, 44);
    [self.view addSubview:bbv];
    
    UIImage *buttonImage = [[UIImage imageNamed:@"button_icon"]resizableImageWithCapInsets:UIEdgeInsetsMake(4, 4, 4, 4)];
    
    self.homeButton = [[[UIButton alloc]initWithFrame:iPad?CGRectMake(358, 4, 62, 36):CGRectMake(123, 4, 62, 36)]autorelease];
    [self.homeButton setImage:buttonImage forState:UIControlStateNormal];
    [self.homeButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.homeButton setTitle:@"Home" forState:UIControlStateNormal];
    [self.homeButton addTarget:self action:@selector(goHome) forControlEvents:UIControlEventTouchUpInside];
    self.homeButton.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    self.homeButton.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    [bbv addSubview:self.homeButton];
    [self.homeButton setHidden:YES];
    
    self.backButton = [[[UIButton alloc]initWithFrame:iPad?CGRectMake(117, 4, 62, 36):CGRectMake(53, 4, 62, 37)]autorelease];
    [self.backButton setTitle:@"Back" forState:UIControlStateNormal];
    [self.backButton addTarget:self action:@selector(goBackDir) forControlEvents:UIControlEventTouchUpInside];
    [self.backButton setImage:buttonImage forState:UIControlStateNormal];
    [self.backButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.backButton.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
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

- (void)cacheCurrentDir {
    NSString *cachePath = [kCachesDir stringByAppendingPathComponent:@"ftp_directory_cache.json"];
    NSData *json = [NSData dataWithContentsOfFile:cachePath];
    NSMutableDictionary *savedDict = [[NSFileManager defaultManager]fileExistsAtPath:cachePath]?[NSJSONSerialization JSONObjectWithData:json options:NSJSONReadingMutableContainers error:nil]:[NSMutableDictionary dictionary];
    
    if (savedDict.count == 0) {
        savedDict = [NSMutableDictionary dictionary];
    }
    
    [savedDict setObject:self.filedicts forKey:[self fixURL:_currentURL]];
    
    NSData *jsontowrite = [NSJSONSerialization dataWithJSONObject:savedDict options:NSJSONReadingMutableContainers error:nil];
    [jsontowrite writeToFile:cachePath atomically:YES];
}

- (void)loadDirFromCacheForURL:(NSString *)url {
    NSString *cachePath = [kCachesDir stringByAppendingPathComponent:@"ftp_directory_cache.json"];
    NSData *json = [NSData dataWithContentsOfFile:cachePath];
    NSMutableDictionary *savedDict = [[NSFileManager defaultManager]fileExistsAtPath:cachePath]?[NSJSONSerialization JSONObjectWithData:json options:NSJSONReadingMutableContainers error:nil]:[NSMutableDictionary dictionary];
    self.filedicts = [NSMutableArray arrayWithArray:[savedDict objectForKey:url]];
}

- (void)loadCurrentDirectoryFromCache {
    NSString *cachePath = [kCachesDir stringByAppendingPathComponent:@"ftp_directory_cache.json"];
    NSData *json = [NSData dataWithContentsOfFile:cachePath];
    NSMutableDictionary *savedDict = [[NSFileManager defaultManager]fileExistsAtPath:cachePath]?[NSJSONSerialization JSONObjectWithData:json options:NSJSONReadingMutableContainers error:nil]:[NSMutableDictionary dictionary];
    
    if ([savedDict objectForKey:[self fixURL:_currentURL]]) {
        self.filedicts = [NSMutableArray arrayWithArray:[savedDict objectForKey:[self fixURL:_currentURL]]];
        [self.theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        [self.pull finishedLoading];
    } else {
        [self loadCurrentDirectory];
    }
}

- (void)loadCurrentDirectory {
    // load SFTP files
}

- (void)showInitialLoginController {
    
    NSString *browserURL = [[NSUserDefaults standardUserDefaults]objectForKey:@"FTPURLBrowser"];
    
    FTPLoginController *controller = [[[FTPLoginController alloc]initWithCompletionHandler:^(NSString *username, NSString *password, NSString *url) {
        if ([username isEqualToString:@"cancel"]) {
            [self dismissModalViewControllerAnimated:YES];
        } else {
            self.currentURL = url;
            [self saveUsername:username andPassword:password forURL:[NSURL URLWithString:_currentURL]];
            self.session = [[CK2SFTPSession alloc] initWithURL:[NSURL URLWithString:url] delegate:self startImmediately:YES];
            // login
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

- (void)SFTPSession:(CK2SFTPSession *)session didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    NSLog(@"challenge");
}

- (void)SFTPSession:(CK2SFTPSession *)session appendStringToTranscript:(NSString *)string received:(BOOL)received {
    NSLog(@"%@", string);
}

- (void)SFTPSessionDidInitialize:(CK2SFTPSession *)session {
    
}

- (void)SFTPSession:(CK2SFTPSession *)session didFailWithError:(NSError *)error {
    
}

- (void)SFTPSession:(CK2SFTPSession *)session didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
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
    
    NSString *concatString = [NSString stringWithFormat:@"%@:%@:%@",username, password, ftpurl.host];
    
    if (index == -1) {
        [triples addObject:concatString];
    } else {
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
    
    SwiftLoadCell *cell = (SwiftLoadCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[[SwiftLoadCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier]autorelease];
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            cell.textLabel.font = [UIFont fontWithName:@"MarkerFelt-Thin" size:27];
            cell.detailTextLabel.font = [UIFont systemFontOfSize:20.0];
        } else {
            cell.textLabel.font = [UIFont fontWithName:@"MarkerFelt-Thin" size:20];
        }
    }
    
    NSDictionary *fileDict = [self.filedicts objectAtIndex:indexPath.row];
    NSString *filename = [fileDict objectForKey:@"NSFileName"];
    
    cell.textLabel.text = filename;
    
    /*if ([(NSString *)[fileDict objectForKey:NSFileType] isEqualToString:(NSString *)NSFileTypeRegular]) {
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
    }*/
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
   /*
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
                [kAppDelegate downloadFileUsingFtp:[_currentFTPURL stringByAppendingPathComponent_URLSafe:filename] withUsername:[creds objectForKey:@"username"] andPassword:[creds objectForKey:@"password"]];
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
    */
    [self.theTableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view {
   // [self sendReqestForCurrentURL];
}

@end
