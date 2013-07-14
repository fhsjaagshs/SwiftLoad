//
//  SFTPBrowserViewController.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 7/5/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "SFTPBrowserViewController.h"

@interface SFTPBrowserViewController () <PullToRefreshViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) ShadowedTableView *theTableView;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) ShadowedNavBar *navBar;
@property (nonatomic, strong) PullToRefreshView *pull;
@property (nonatomic, strong) NSString *currentURL;
@property (nonatomic, strong) NSMutableArray *filedicts;

@property (nonatomic, strong) DLSFTPConnection *connection;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;

@property (nonatomic, strong) NSString *currentPath;
@end

@implementation SFTPBrowserViewController

- (void)loadView {
    [super loadView];
    
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    
    self.view = [StyleFactory backgroundView];
    
    self.navBar = [[ShadowedNavBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)];
    self.navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"/"];
    topItem.rightBarButtonItem = nil;
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    [self.navBar pushNavigationItem:topItem animated:YES];
    [self.view addSubview:self.navBar];
    
    UIImageView *bbv = [StyleFactory buttonBarImageView];
    bbv.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    bbv.frame = CGRectMake(0, 44, screenBounds.size.width, 44);
    [self.view addSubview:bbv];
    
    self.backButton = [UIButton customizedButton];
    _backButton.frame = CGRectMake(10, 6, 62, 31);
    [_backButton setTitle:@"Back" forState:UIControlStateNormal];
    [_backButton addTarget:self action:@selector(goBackDir) forControlEvents:UIControlEventTouchUpInside];
    [bbv addSubview:_backButton];
    [_backButton setHidden:YES];
    
    self.theTableView = [[ShadowedTableView alloc]initWithFrame:CGRectMake(0, 88, screenBounds.size.width, screenBounds.size.height-88) style:UITableViewStylePlain];
    self.theTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.theTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.theTableView.backgroundColor = [UIColor clearColor];
    self.theTableView.rowHeight = iPad?60:44;
    self.theTableView.dataSource = self;
    self.theTableView.delegate = self;
    [self.view addSubview:self.theTableView];
    
    self.pull = [[PullToRefreshView alloc]initWithScrollView:self.theTableView];
    [self.pull setDelegate:self];
    [self.theTableView addSubview:self.pull];
    
    self.filedicts = [NSMutableArray array];
    
    [self showInitialLoginController];
}

- (void)goBackDir {
    [self deleteLastPathComponent];
    [self loadCurrentDirectoryFromCache];
    
    if (_currentPath.length <= 1) {
        [_backButton setHidden:YES];
    }
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
    NSString *cachePath = [kCachesDir stringByAppendingPathComponent:@"sftp_directory_cache.json"];
    NSData *json = [NSData dataWithContentsOfFile:cachePath];
    NSMutableDictionary *savedDict = [[NSFileManager defaultManager]fileExistsAtPath:cachePath]?[NSJSONSerialization JSONObjectWithData:json options:NSJSONReadingMutableContainers error:nil]:[NSMutableDictionary dictionary];

    [savedDict setObject:_filedicts forKey:[self fixURL:_currentURL]];
    
    NSData *jsontowrite = [NSJSONSerialization dataWithJSONObject:savedDict options:NSJSONReadingMutableContainers error:nil];
    [jsontowrite writeToFile:cachePath atomically:YES];
}

- (void)loadCurrentDirectoryFromCache {
    self.filedicts = [NSMutableArray array];
    NSString *cachePath = [kCachesDir stringByAppendingPathComponent:@"sftp_directory_cache.json"];
    NSData *json = [NSData dataWithContentsOfFile:cachePath];
    NSMutableDictionary *savedDict = [[NSFileManager defaultManager]fileExistsAtPath:cachePath]?[NSJSONSerialization JSONObjectWithData:json options:NSJSONReadingMutableContainers error:nil]:[NSMutableDictionary dictionary];
    
    if ([savedDict objectForKey:[self fixURL:_currentURL]]) {
        [_filedicts addObjectsFromArray:[savedDict objectForKey:[self fixURL:_currentURL]]];
        [_theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        [_pull finishedLoading];
    } else {
        [_filedicts removeAllObjects];
        [_theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        [self loadCurrentDirectoryFromSFTP];
    }
}

- (void)loadCurrentDirectoryFromSFTP {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    DLSFTPRequest *req = [[DLSFTPListFilesRequest alloc]initWithDirectoryPath:_currentPath successBlock:^(NSArray *array) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            @autoreleasepool {
            
                for (DLSFTPFile *sftpFile in array) {
                    NSDictionary *dict = @{@"NSFileName": sftpFile.filename, NSFileType:[sftpFile.attributes objectForKey:NSFileType], NSFileSize: [sftpFile.attributes objectForKey:NSFileSize], @"NSFilePath": sftpFile.path};
                    [_filedicts addObject:dict];
                }
        
                [_theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
                [_pull finishedLoading];
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            }
        });
    } failureBlock:^(NSError *error) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            @autoreleasepool {
                [_theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
                [_pull finishedLoading];
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            }
            [TransparentAlert showAlertWithTitle:@"SFTP Error" andMessage:@"There was an error loading the current directory via SFTP."]; // Improve this later
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
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
            [_connection connectWithSuccessBlock:^{
                dispatch_sync(dispatch_get_main_queue(), ^{
                    @autoreleasepool {
                        [self loadCurrentDirectoryFromSFTP];
                    }
                });
            } failureBlock:^(NSError *error) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    @autoreleasepool {
                        [TransparentAlert showAlertWithTitle:@"SFTP Login Error" andMessage:@"There was an issue logging in via SFTP."]; // improve this later
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
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_connection cancelAllRequests];
        [_connection disconnect];
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
    NSString *filename = [fileDict objectForKey:@"NSFileName"];
    
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

- (NSURL *)constructURLForFile:(NSString *)filename {
    return [NSURL URLWithString:[[NSString stringWithFormat:@"sftp://%@%@%@",[[NSURL URLWithString:_currentURL]host],[self fixURL:_currentPath],filename]stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *fileDict = [self.filedicts objectAtIndex:indexPath.row];
    NSString *filename = [fileDict objectForKey:NSFileName];
    
    NSString *filetype = (NSString *)[fileDict objectForKey:NSFileType];
    
    if ([filetype isEqualToString:(NSString *)NSFileTypeDirectory]) {
        [self addComponentToPath:filename];
        [self loadCurrentDirectoryFromCache];
        if (_currentPath.length > 1) {
            [_backButton setHidden:NO];
        }
    } else if ([filetype isEqualToString:(NSString *)NSFileTypeRegular]) {
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
    [self loadCurrentDirectoryFromSFTP];
}


@end
