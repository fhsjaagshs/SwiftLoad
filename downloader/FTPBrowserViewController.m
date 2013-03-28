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
@property (nonatomic, retain) CustomNavBar *navBar;
@property (nonatomic, retain) PullToRefreshView *pull;

@property (nonatomic, retain) NSString *currentFTPURL;
@property (nonatomic, retain) NSString *originalFTPURL;
@property (nonatomic, retain) NSMutableArray *filedicts;

@end

@implementation FTPBrowserViewController

- (void)loadView {
    [super loadView];
    
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    
    self.view = [[[UIView alloc]initWithFrame:screenBounds]autorelease];
    self.view.backgroundColor = [UIColor clearColor];
    
    self.navBar = [[[CustomNavBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)]autorelease];
    self.navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[[UINavigationItem alloc]initWithTitle:@"/"]autorelease];
    topItem.leftBarButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)]autorelease];
    [self.navBar pushNavigationItem:topItem animated:YES];
    [self.view addSubview:self.navBar];
    [self.view bringSubviewToFront:self.navBar];
    
    ButtonBarView *bbv = [[[ButtonBarView alloc]initWithFrame:CGRectMake(0, 44, screenBounds.size.width, 44)]autorelease];
    bbv.autoresizingMask = UIViewAutoresizingFlexibleWidth;
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
    self.theTableView.allowsSelectionDuringEditing = YES;
    [self.view addSubview:self.theTableView];
    
    self.pull = [[[PullToRefreshView alloc]initWithScrollView:self.theTableView]autorelease];
    [self.pull setDelegate:self];
    [self.theTableView addSubview:self.pull];
}

- (id)initWithURL:(NSString *)ftpurl {
    self = [super init];
    if (self) {
        self.currentFTPURL = ftpurl;
        self.originalFTPURL = ftpurl;
    }
    return self;
}

- (void)listFinished:(SCRFTPRequest *)request {
    self.filedicts = [[request.directoryContents mutableCopy]autorelease];
    [self cacheCurrentDir];
    NSLog(@"Directory Contents: %@",request.directoryContents);
    [self.theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    [self.pull finishedLoading];
    [request release];
}

- (void)listFailed:(SCRFTPRequest *)request {
    NSLog(@"Request Error: %@",request.error);
    [self.pull finishedLoading];
    [request release];
}

- (void)listWillStart:(SCRFTPRequest *)request {
    NSLog(@"starting");
}

- (void)removeCredsForURL:(NSURL *)ftpurl {
    KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc]initWithIdentifier:@"SwiftLoadFTPCreds" accessGroup:nil];
    
    NSString *keychainData = (NSString *)[keychain objectForKey:(id)kSecValueData];
    
    int index = -1;
    
    NSMutableArray *triples = [[[keychainData componentsSeparatedByString:@","]mutableCopy]autorelease];
    
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
    
    NSMutableArray *triples = [[[keychainData componentsSeparatedByString:@","]mutableCopy]autorelease];
    
    for (NSString *string in triples) {
        NSArray *components = [keychainData componentsSeparatedByString:@":"];
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
    
    // username:password:host, username:password:host, username:password:host
    
    NSString *username = nil;
    NSString *password = nil;
    
    NSArray *triples = [keychainData componentsSeparatedByString:@","];
    
    for (NSString *string in triples) {
        NSArray *components = [keychainData componentsSeparatedByString:@":"];
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

- (void)sendReqestForURL:(NSString *)url andUsename:(NSString *)username andPassword:(NSString *)password{
    SCRFTPRequest *ftpRequest = [[SCRFTPRequest requestWithURLToListDirectory:[NSURL URLWithString:url]]retain];
    ftpRequest.username = username;
    ftpRequest.password = password;
    ftpRequest.delegate = self;
    ftpRequest.didFinishSelector = @selector(listFinished:);
    ftpRequest.didFailSelector = @selector(listFailed:);
    ftpRequest.willStartSelector = @selector(listWillStart:);
    [ftpRequest startRequest];
    [self.pull setState:PullToRefreshViewStateLoading];
}

- (void)listFilesInRemoteDirectory:(NSString *)url isInitialRequest:(BOOL)isInitialRequest {
    
    NSDictionary *creds = [self getCredsForURL:[NSURL URLWithString:url]];
    
    if (creds) {
        NSString *username = [creds objectForKey:@"username"];
        NSString *password = [creds objectForKey:@"password"];
        
        if (isInitialRequest) {
            NSString *message = [NSString stringWithFormat:@"Do you want to use the username \"%@\" and the password \"%@\"?",username, password];
            CustomAlertView *alertView = [[[CustomAlertView alloc]initWithTitle:@"Use Saved Credentials?" message:message completionBlock:^(NSUInteger buttonIndex, UIAlertView *alertView) {
                
                if (buttonIndex == 0) {
                    FTPLoginController *controller = [[[FTPLoginController alloc]initWithCompletionHandler:^(NSString *username, NSString *password, NSString *url) {
                        if ([username isEqualToString:@"cancel"]) {
                            [self dismissModalViewControllerAnimated:YES];
                        } else {
                            [self sendReqestForURL:url andUsename:username andPassword:password];
                        }
                    }]autorelease];
                    [controller setUrl:url isPredefined:YES];
                    [controller setType:FTPLoginControllerTypeLogin];
                    [controller show];
                } else {
                    [self sendReqestForURL:url andUsename:username andPassword:password];
                }
                
            } cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil]autorelease];
            [alertView show];
        } else {
            [self sendReqestForURL:url andUsename:username andPassword:password];
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filedicts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *CellIdentifier = @"CellFTP";
    
    CustomCellCell *cell = (CustomCellCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[[CustomCellCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier]autorelease];
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            cell.accessoryView.center = CGPointMake(735, (cell.bounds.size.height)/2);
            cell.textLabel.font = [UIFont fontWithName:@"MarkerFelt-Thin" size:27];
            cell.detailTextLabel.font = [UIFont systemFontOfSize:20.0];
        } else {
            cell.accessoryView.center = CGPointMake(297.5, (cell.bounds.size.height)/2);
            cell.textLabel.font = [UIFont fontWithName:@"MarkerFelt-Thin" size:20];
        }
    }
    
    NSDictionary *fileDict = [self.filedicts objectAtIndex:indexPath.row];
    NSString *filename = [fileDict objectForKey:NSFileName];
    
    cell.textLabel.text = filename;
    
    NSString *detailText = ([fileDict objectForKey:NSFileType] == NSFileTypeDirectory)?@"Directory, ":@"File, ";
    
    float fileSize = [[fileDict objectForKey:NSFileSize]intValue];
    
    if (fileSize < 1024.0) {
        detailText = [detailText stringByAppendingFormat:@"%.0f Byte%@",fileSize,(fileSize > 1)?@"s":@""];
    } else if (fileSize < (1024*1024) && fileSize > 1024.0 ) {
        fileSize = fileSize/1014;
        detailText = [detailText stringByAppendingFormat:@"%.0f KB",fileSize];
    } else if (fileSize < (1024*1024*1024) && fileSize > (1024*1024)) {
        fileSize = fileSize/(1024*1024);
        detailText = [detailText stringByAppendingFormat:@"%.0f MB",fileSize];
    }
    cell.detailTextLabel.text = detailText;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary *fileDict = [self.filedicts objectAtIndex:indexPath.row];
    NSString *filename = [fileDict objectForKey:NSFileName];
    BOOL isDir = [fileDict objectForKey:NSFileType] == NSFileTypeDirectory;
    
    if (isDir) {
        self.navBar.topItem.title = [self.navBar.topItem.title stringByAppendingPathComponent:self.currentFTPURL];
        self.currentFTPURL = [self.currentFTPURL stringByAppendingPathComponent:filename];
        [self loadCurrentDirectory];
        if (self.currentFTPURL.length > self.originalFTPURL.length) {
            [self setButtonsHidden:NO];
        }
    } else {
        UIActionSheet *actionSheet = [[[UIActionSheet alloc]initWithTitle:@"Do you wish to download " completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
            if (buttonIndex == 1) {
                [kAppDelegate downloadFileUsingFtp:[self.currentFTPURL stringByAppendingPathComponent:filename]];
            }
        } cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Download", nil]autorelease];
        actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        [actionSheet showInView:self.view];
    }
    
    [self.theTableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
        [NSThread sleepForTimeInterval:0.5f];
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSAutoreleasePool *poolTwo = [[NSAutoreleasePool alloc]init];
            [self listFilesInRemoteDirectory:self.currentFTPURL isInitialRequest:NO];
            [poolTwo release];
        });
        [pool release];
    });
}

- (void)cacheCurrentDir {
    NSString *cachePath = [kCachesDir stringByAppendingPathComponent:@"cachedFTPDirs.plist"];
    NSMutableDictionary *savedDict = [NSMutableDictionary dictionaryWithContentsOfFile:cachePath];
    [savedDict setObject:self.filedicts forKey:self.currentFTPURL];
    [savedDict writeToFile:cachePath atomically:YES];
}

- (void)loadDirFromCacheForURL:(NSString *)url {
    NSString *cachePath = [kCachesDir stringByAppendingPathComponent:@"cachedFTPDirs.plist"];
    NSMutableDictionary *savedDict = [NSMutableDictionary dictionaryWithContentsOfFile:cachePath];
    self.filedicts = [savedDict objectForKey:url];
}

- (void)loadCurrentDirectory {
    NSString *cachePath = [kCachesDir stringByAppendingPathComponent:@"cachedFTPDirs.plist"];
    NSMutableDictionary *savedDict = [NSMutableDictionary dictionaryWithContentsOfFile:cachePath];
    
    if ([savedDict objectForKey:self.currentFTPURL]) {
        self.filedicts = [savedDict objectForKey:self.currentFTPURL];
    } else {
        [self listFilesInRemoteDirectory:self.currentFTPURL isInitialRequest:NO];
    }
}

- (void)setButtonsHidden:(BOOL)shouldHide {
    [self.backButton setHidden:shouldHide];
    [self.homeButton setHidden:shouldHide];
}

- (void)goBackDir {
    if (self.currentFTPURL.length > self.originalFTPURL.length) {
        self.currentFTPURL = [self.currentFTPURL stringByDeletingLastPathComponent];
        [self loadCurrentDirectory];
        [self.theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        [self.pull finishedLoading];
        
        if (self.currentFTPURL.length <= self.originalFTPURL.length) {
            [self setButtonsHidden:YES];
        }
    } 
}

- (void)dealloc {
    [self setPull:nil];
    [self setTheTableView:nil];
    [self setBackButton:nil];
    [self setHomeButton:nil];
    [self setNavBar:nil];
    [self setCurrentFTPURL:nil];
    [self setFiledicts:nil];
    [super dealloc];
}

@end
