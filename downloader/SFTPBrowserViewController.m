//
//  SFTPBrowserViewController.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 7/5/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "SFTPBrowserViewController.h"

@interface SFTPBrowserViewController () <PullToRefreshViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *theTableView;
@property (nonatomic, strong) ShadowedNavBar *navBar;
@property (nonatomic, strong) PullToRefreshView *pull;
@property (nonatomic, strong) NSString *currentURL;
@property (nonatomic, strong) NSMutableArray *filedicts;

@property (nonatomic, strong) DLSFTPConnection *connection;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;

@property (nonatomic, strong) NSString *currentPath;

@property (nonatomic, strong) FMDatabase *memCache;

@end

@implementation SFTPBrowserViewController

- (void)loadView {
    [super loadView];
    
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    
    self.navBar = [[ShadowedNavBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)];
    self.navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"/"];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"ArrowLeft"] style:UIBarButtonItemStyleBordered target:self action:@selector(goBackDir)];
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    [self.navBar pushNavigationItem:topItem animated:YES];
    [self.view addSubview:self.navBar];

    self.theTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 44, screenBounds.size.width, screenBounds.size.height-44) style:UITableViewStylePlain];
    self.theTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.theTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.theTableView.rowHeight = iPad?60:44;
    self.theTableView.dataSource = self;
    self.theTableView.delegate = self;
    [self.view addSubview:self.theTableView];
    
    self.pull = [[PullToRefreshView alloc]initWithScrollView:self.theTableView];
    [self.pull setDelegate:self];
    [self.theTableView addSubview:self.pull];
    
    self.filedicts = [NSMutableArray array];
    
    [self showInitialLoginController];
    
    self.memCache = [FMDatabase databaseWithPath:nil]; // nil path means that the database will be created in memory: lighting fuckin fast
    [_memCache open];
    [_memCache executeUpdate:@"CREATE TABLE sftp_cache (id INTEGER PRIMARY KEY AUTOINCREMENT, parentpath VARCHAR(255) DEFAULT NULL, filename VARCHAR(255) DEFAULT NULL, type VARCHAR(255) DEFAULT NULL, size INTEGER)"];
}

- (void)goBackDir {
    
    [_connection cancelAllRequests];
    
    [_filedicts removeAllObjects];
    
    [self deleteLastPathComponent];
    [self loadCurrentDirectoryFromCache];
    
    _navBar.topItem.leftBarButtonItem.enabled = (_currentPath.length > 1);
}

- (NSString *)fixURL:(NSString *)url {
    
    if ([url isEqualToString:@"/"]) {
        return @"/";
    }
    
    NSString *lastChar = [url substringFromIndex:url.length-1];
    if (![lastChar isEqualToString:@"/"]) {
        return [url stringByAppendingString:@"/"];
    }
    return url;
}

- (void)cacheCurrentDir {
    
    NSString *parentpath = [self fixURL:_currentPath];
    
    [_memCache executeUpdate:@"DELETE * FROM sftp_cache WHERE parentpath=?",parentpath];
    NSMutableString *query = [NSMutableString stringWithFormat:@"INSERT INTO sftp_cache (parentpath,filename,type,size) VALUES "];
    
    for (NSDictionary *dict in _filedicts) {
        NSString *filename = [dict objectForKey:NSFileName];
        NSString *type = [dict objectForKey:NSFileType];
        int size = [[dict objectForKey:NSFileSize]intValue];
        [query appendFormat:@"(\"%@\",\"%@\",\"%@\",%d),",parentpath,filename,type,size];
    }
    
    [query deleteCharactersInRange:NSMakeRange(query.length-1, 1)];
    
    [_memCache executeUpdate:query];
}

- (void)loadCurrentDirectoryFromCache {
    self.filedicts = [NSMutableArray array];
    
    FMResultSet *set = [_memCache executeQuery:@"SELECT filename,type,size FROM sftp_cache WHERE parentpath=?",[self fixURL:_currentPath]];
    
    while ([set next]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setObject:[set stringForColumn:@"filename"] forKey:NSFileName];
        [dict setObject:[NSNumber numberWithLongLong:[set intForColumn:@"size"]] forKey:NSFileSize];
        [dict setObject:[set stringForColumn:@"type"] forKey:NSFileType];
        [_filedicts addObject:dict];
    }

    if (_filedicts.count == 0) {
        [self loadCurrentDirectoryFromSFTP];
    } else {
        [_theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationRight];
    }
}

- (void)loadCurrentDirectoryFromSFTP {
    [[NetworkActivityController sharedController]show];
    [_pull setState:PullToRefreshViewStateLoading];
    self.filedicts = [NSMutableArray array];
    [_theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    
    DLSFTPRequest *req = [[DLSFTPListFilesRequest alloc]initWithDirectoryPath:_currentPath successBlock:^(NSArray *array) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            @autoreleasepool {
                for (DLSFTPFile *sftpFile in array) {
                    NSDictionary *dict = @{@"NSFileName": sftpFile.filename, NSFileType:[sftpFile.attributes objectForKey:NSFileType], NSFileSize: [sftpFile.attributes objectForKey:NSFileSize], @"NSFilePath": sftpFile.path};
                    [_filedicts addObject:dict];
                }
        
                [self cacheCurrentDir];
                
                [_theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationRight];
                [_pull finishedLoading];
                [[NetworkActivityController sharedController]hideIfPossible];
            }
        });
    } failureBlock:^(NSError *error) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            @autoreleasepool {
                [_theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
                [_pull finishedLoading];
                [[NetworkActivityController sharedController]hideIfPossible];
                [TransparentAlert showAlertWithTitle:@"SFTP Error" andMessage:error.localizedDescription]; // Improve this later
            }
        });
    }];
    [_connection submitRequest:req];
}

- (void)addComponentToPath:(NSString *)pathComponent {
    self.currentPath = [self fixURL:[_currentPath stringByAppendingPathComponent:pathComponent]];
    self.navBar.topItem.title = _currentPath;
}

- (void)deleteLastPathComponent {
    self.currentPath = [self fixURL:[_currentPath stringByDeletingLastPathComponent]];
    self.navBar.topItem.title = _currentPath;
}

- (void)showInitialLoginController {
    
    FTPLoginController *controller = [[FTPLoginController alloc]initWithType:FTPLoginControllerTypeLogin andCompletionHandler:^(NSString *username, NSString *password, NSString *url) {
        if ([username isEqualToString:@"cancel"]) {
            [self dismissModalViewControllerAnimated:YES];
        } else {
            self.currentURL = url;
            NSURL *URL = [NSURL URLWithString:_currentURL];
            [SFTPCreds saveUsername:username andPassword:password forURL:URL];
            self.currentPath = URL.path;
            self.navBar.topItem.title = _currentPath;
            self.username = username;
            self.password = password;
            self.connection = [[DLSFTPConnection alloc]initWithHostname:URL.host username:_username password:_password];
            [[NetworkActivityController sharedController]show];
            [_pull setState:PullToRefreshViewStateLoading];
            [_connection connectWithSuccessBlock:^{
                dispatch_sync(dispatch_get_main_queue(), ^{
                    @autoreleasepool {
                        [[NetworkActivityController sharedController]hideIfPossible];
                        _navBar.topItem.leftBarButtonItem.enabled = (_currentPath.length > 1);
                        [self loadCurrentDirectoryFromSFTP];
                    }
                });
            } failureBlock:^(NSError *error) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    @autoreleasepool {
                        [[NetworkActivityController sharedController]hideIfPossible];
                        _navBar.topItem.leftBarButtonItem.enabled = (_currentPath.length > 1);
                        [TransparentAlert showAlertWithTitle:@"SFTP Login Error" andMessage:error.localizedDescription]; // improve this later
                        [_theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationRight];
                        [_pull finishedLoading];
                    }
                });
            }];
        }
    }];
    controller.isSFTP = YES;
    controller.textFieldDelegate = self;
    controller.didMoveOnSelector = @selector(didMoveOn);
    
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
        NSDictionary *creds = [SFTPCreds getCredsForURL:[NSURL URLWithString:url]];
        
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
    [_connection cancelAllRequests];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            [_connection disconnect];
        }
    });
    [self dismissModalViewControllerAnimated:YES];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _filedicts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    SwiftLoadCell *cell = (SwiftLoadCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[SwiftLoadCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    NSDictionary *fileDict = [_filedicts objectAtIndex:indexPath.row];

    cell.textLabel.text = [fileDict objectForKey:NSFileName];
    
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
    
    cell.isFirstCell = (indexPath.row == 0);
    
    [cell setNeedsDisplay];
    
    return cell;
}

- (NSURL *)constructURLForFile:(NSString *)filename {
    return [NSURL URLWithString:[[NSString stringWithFormat:@"sftp://%@%@%@",[[NSURL URLWithString:_currentURL]host],[self fixURL:_currentPath],filename]stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *fileDict = [_filedicts objectAtIndex:indexPath.row];
    NSString *filename = [fileDict objectForKey:NSFileName];
    
    NSString *filetype = (NSString *)[fileDict objectForKey:NSFileType];
    
    if ([filetype isEqualToString:NSFileTypeDirectory]) {
        [self addComponentToPath:filename];
        [self loadCurrentDirectoryFromSFTP];
        
        _navBar.topItem.leftBarButtonItem.enabled = (_currentPath.length > 1);
    } else if ([filetype isEqualToString:NSFileTypeRegular]) {
        NSString *message = [NSString stringWithFormat:@"Do you wish to download \"%@\"?",filename];
        UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:message completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
            if (buttonIndex == 0) {
                NSDictionary *creds = [SFTPCreds getCredsForURL:[NSURL URLWithString:_currentURL]];
                [kAppDelegate downloadFileUsingSFTP:[self constructURLForFile:filename] withUsername:[creds objectForKey:@"username"] andPassword:[creds objectForKey:@"password"]];
            }
        } cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Download", nil];
        actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        [actionSheet showInView:self.view];
    }
    [_theTableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view {
    [_connection cancelAllRequests];
    [self loadCurrentDirectoryFromSFTP];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
