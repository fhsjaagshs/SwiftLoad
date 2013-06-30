//
//  DropboxBrowserViewController.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 3/30/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "DropboxBrowserViewController.h"
#import "CustomCellCell.h"

static NSString *CellIdentifier = @"dbcell";

@interface NSString (normalize)

- (NSString *)fhs_normalize;

@end

@implementation NSString (normalize)

- (NSString *)fhs_normalize {
    if (![[self substringFromIndex:1]isEqualToString:@"/"]) {
        return [[self lowercaseString]stringByAppendingString:@"/"];
    }
    return [self lowercaseString];
}

@end

@interface DropboxBrowserViewController () <UITableViewDataSource, UITableViewDelegate, PullToRefreshViewDelegate>

@property (nonatomic, retain) ShadowedTableView *theTableView;
@property (nonatomic, retain) UIButton *backButton;
@property (nonatomic, retain) UIButton *homeButton;
@property (nonatomic, retain) ShadowedNavBar *navBar;
@property (nonatomic, retain) PullToRefreshView *pull;

@property (nonatomic, retain) NSMutableArray *currentPathItems;

@property (nonatomic, retain) NSString *cursor;

@end

@implementation DropboxBrowserViewController

- (void)loadView {
    [super loadView];
    
    [[CentralFactory sharedFactory]loadDatabase];
    
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    
    self.view = [StyleFactory backgroundImageView];
    
    self.navBar = [[[ShadowedNavBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)]autorelease];
    _navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[[UINavigationItem alloc]initWithTitle:@"/"]autorelease];
    topItem.rightBarButtonItem = nil;
    topItem.leftBarButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)]autorelease];
    [_navBar pushNavigationItem:topItem animated:YES];
    [self.view addSubview:_navBar];
    
    UIImageView *bbv = [StyleFactory buttonBarImageView];
    bbv.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    bbv.frame = CGRectMake(0, 44, screenBounds.size.width, 44);
    [self.view addSubview:bbv];
    
    UIImage *buttonImage = [[UIImage imageNamed:@"button_icon"]resizableImageWithCapInsets:UIEdgeInsetsMake(4, 4, 4, 4)];
    
    self.homeButton = [[[UIButton alloc]initWithFrame:iPad?CGRectMake(358, 4, 62, 36):CGRectMake(135, 6, 50, 31)]autorelease];
    [_homeButton setTitle:@"Home" forState:UIControlStateNormal];
    [_homeButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [_homeButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_homeButton addTarget:self action:@selector(goHome) forControlEvents:UIControlEventTouchUpInside];
    _homeButton.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    _homeButton.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    [bbv addSubview:_homeButton];
    [_homeButton setHidden:YES];
    
    self.backButton = [[[UIButton alloc]initWithFrame:iPad?CGRectMake(117, 4, 62, 36):CGRectMake(53, 6, 62, 31)]autorelease];
    [_backButton setTitle:@"Back" forState:UIControlStateNormal];
    [_backButton addTarget:self action:@selector(goBackDir) forControlEvents:UIControlEventTouchUpInside];
    [_backButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [_backButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    _backButton.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    _backButton.titleLabel.shadowColor = [UIColor blackColor];
    _backButton.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    [bbv addSubview:_backButton];
    [_backButton setHidden:YES];
    
    self.theTableView = [[[ShadowedTableView alloc]initWithFrame:CGRectMake(0, 88, screenBounds.size.width, screenBounds.size.height-88) style:UITableViewStylePlain]autorelease];
    _theTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _theTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _theTableView.backgroundColor = [UIColor clearColor];
    _theTableView.rowHeight = iPad?60:44;
    _theTableView.dataSource = self;
    _theTableView.delegate = self;
    [self.view addSubview:_theTableView];
    
    self.pull = [[[PullToRefreshView alloc]initWithScrollView:_theTableView]autorelease];
    [_pull setDelegate:self];
    [_theTableView addSubview:_pull];

    self.currentPathItems = [NSMutableArray array];
}

- (void)loadContentsOfDirectory:(NSString *)string {
    [[[CentralFactory sharedFactory]database]open];
    FMResultSet *s = [[[CentralFactory sharedFactory]database]executeQuery:@"SELECT * FROM DropboxData where lowercasepath=? and user_id=? ORDER BY filename",[string lowercaseString],[[CentralFactory sharedFactory]userID]];
    [_currentPathItems removeAllObjects];
    while ([s next]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        NSString *filename = [s stringForColumn:@"filename"];
        [dict setObject:filename forKey:NSFileName];
        [dict setObject:[NSNumber numberWithLongLong:[s doubleForColumn:@"size"]] forKey:NSFileSize];
        [dict setObject:[NSDate dateWithTimeIntervalSince1970:[s intForColumn:@"date"]] forKey:NSFileCreationDate];
        [dict setObject:([s intForColumn:@"type"]== 1)?NSFileTypeRegular:NSFileTypeDirectory forKey:NSFileType];
        [_currentPathItems addObject:dict];
    }
    [[[CentralFactory sharedFactory]database]close];
}

- (void)removeAllEntriesForCurrentUser {
    [[[CentralFactory sharedFactory]database]open];
    [[[CentralFactory sharedFactory]database]executeQuery:@"DELETE FROM DropboxData WHERE user_id=?",[[CentralFactory sharedFactory]userID]];
    [[[CentralFactory sharedFactory]database]close];
}

- (void)removeItemWithLowercasePath:(NSString *)path {
    [[[CentralFactory sharedFactory]database]open];
    [[[CentralFactory sharedFactory]database]executeQuery:@"DELETE FROM DropboxData WHERE lowercasepath=? and user_id=?",[path lowercaseString],[[CentralFactory sharedFactory]userID]];
    [[[CentralFactory sharedFactory]database]close];
}

- (void)addObjectToDatabase:(DBMetadata *)item withLowercasePath:(NSString *)lowercasePath {
    // DropboxData (id INTEGER PRIMARY KEY, lowercasepath VARCHAR, filename VARCHAR, date INTEGER, size INTEGER, type INTEGER, user_id VARCHAR(255)
    
    NSString *filename = item.filename;
    int type = item.isDirectory?2:1;
    float date = item.lastModifiedDate.timeIntervalSince1970;
    float size = item.totalBytes;
    [[[CentralFactory sharedFactory]database]open];
    [[[CentralFactory sharedFactory]database]executeQuery:@"begin tran IF EXISTS (SELECT * FROM DropboxData WHERE filename=? and lowercasepath=? and user_id=?) UPDATE DropboxData SET date=?,size=? WHERE filename=?,lowercasepath=? ELSE INSERT INTO DropboxData VALUES (date=?,size=?,type=?,filename=?,lowercasepath=?,user_id=?) commit",filename,lowercasePath,[[CentralFactory sharedFactory]userID],date,size,filename,lowercasePath,date,size,type,filename,lowercasePath,[[CentralFactory sharedFactory]userID]];
    [[[CentralFactory sharedFactory]database]close];
}

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view {
    [_pull setState:PullToRefreshViewStateLoading];
    [self loadUserID];
}

- (void)loadUserID {
    NSLog(@"loadUserID");
    NSString *userID = [[CentralFactory sharedFactory]userID];
    if (userID.length == 0) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        [DroppinBadassBlocks loadAccountInfoWithCompletionBlock:^(DBAccountInfo *info, NSError *error) {
            [[CentralFactory sharedFactory]setUserID:info.userId];
            [self loadUserID];
        }];
    } else {
        NSString *filePath = [kCachesDir stringByAppendingPathComponent:@"cursors.json"];
        NSDictionary *dict = [[NSFileManager defaultManager]fileExistsAtPath:filePath]?[NSJSONSerialization JSONObjectWithStream:[NSInputStream inputStreamWithFileAtPath:filePath] options:NSJSONReadingMutableContainers error:nil]:[NSMutableDictionary dictionary];
        self.cursor = [dict objectForKey:userID];
        [self updateFileListing];
    }
}

- (void)saveCursor {
    NSString *filePath = [kCachesDir stringByAppendingPathComponent:@"cursors.json"];
    NSMutableDictionary *dict = [[NSFileManager defaultManager]fileExistsAtPath:filePath]?[NSJSONSerialization JSONObjectWithStream:[NSInputStream inputStreamWithFileAtPath:filePath] options:NSJSONReadingMutableContainers error:nil]:[NSMutableDictionary dictionary];
    [dict setObject:_cursor forKey:[[CentralFactory sharedFactory]userID]];
    NSData *json = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONReadingMutableContainers error:nil];
    [json writeToFile:filePath atomically:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    if (![[DBSession sharedSession]isLinked]) {
        [[DBSession sharedSession]linkFromController:self];
    } else {
        [_pull setState:PullToRefreshViewStateLoading];
        [self loadUserID];
    }
}

- (void)updateFileListing {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [DroppinBadassBlocks loadDelta:_cursor withCompletionHandler:^(NSArray *entries, NSString *cursor, BOOL hasMore, BOOL shouldReset, NSError *error) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        if (error) {
            NSLog(@"Error: %@",error);
        } else {
            
            if (shouldReset) {
                NSLog(@"Resetting");
                self.cursor = nil;
                [_currentPathItems removeAllObjects];
                [self removeAllEntriesForCurrentUser];
            }

            self.cursor = cursor;
            
            for (DBDeltaEntry *entry in entries) {
                DBMetadata *item = entry.metadata;
                if (!item) {
                    [self removeItemWithLowercasePath:entry.lowercasePath];
                } else {
                    [self addObjectToDatabase:item withLowercasePath:entry.lowercasePath];
                }
            }
            
            if (hasMore) {
                NSLog(@"Continuing");
                [self updateFileListing];
            } else {
                NSLog(@"done");
                [self refreshStateWithAnimationStyle:UITableViewRowAnimationFade];
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            }
        }
    }];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _currentPathItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
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
    
    NSDictionary *fileDict = [_currentPathItems objectAtIndex:indexPath.row];
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

    NSDictionary *fileDict = [_currentPathItems objectAtIndex:indexPath.row];
    NSString *filename = [fileDict objectForKey:NSFileName];
    
    NSString *filetype = (NSString *)[fileDict objectForKey:NSFileType];
    
    if ([filetype isEqualToString:(NSString *)NSFileTypeDirectory]) {
        _navBar.topItem.title = [fileDict objectForKey:NSFileDBPath];
        [self loadContentsOfDirectory:[_navBar.topItem.title fhs_normalize]];
        [self refreshStateWithAnimationStyle:UITableViewRowAnimationLeft];
    } else {
        NSString *message = [NSString stringWithFormat:@"Do you wish to download \"%@\"?",filename];
        UIActionSheet *actionSheet = [[[UIActionSheet alloc]initWithTitle:message completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
            if (buttonIndex == 0) {
                
                [kAppDelegate showHUDWithTitle:@"Downloading"];
                [kAppDelegate setVisibleHudMode:MBProgressHUDModeDeterminate];
                [kAppDelegate setSecondaryTitleOfVisibleHUD:filename];
                
                [DroppinBadassBlocks loadFile:[fileDict objectForKey:NSFileDBPath] intoPath:getNonConflictingFilePathForPath([kDocsDir stringByAppendingPathComponent:filename]) withCompletionBlock:^(DBMetadata *metadata, NSError *error) {
                    if (error) {
                        [kAppDelegate showFailedAlertForFilename:metadata.filename];
                    } else {
                        [kAppDelegate showFinishedAlertForFilename:metadata.filename];
                    }
                } andProgressBlock:^(float progress) {
                    [kAppDelegate setProgressOfVisibleHUD:progress];
                }];
                
            } else if (buttonIndex == 1) {
                
                [kAppDelegate showHUDWithTitle:@"Loading Link..."];
                [kAppDelegate setVisibleHudMode:MBProgressHUDModeIndeterminate];
                [kAppDelegate setSecondaryTitleOfVisibleHUD:filename];
                
                [DroppinBadassBlocks loadSharableLinkForFile:[fileDict objectForKey:NSFileDBPath] andCompletionBlock:^(NSString *link, NSString *path, NSError *error) {
                    [kAppDelegate hideHUD];
                    if (error) {
                        [kAppDelegate showFailedAlertForFilename:path.lastPathComponent];
                    } else {
                        TransparentAlert *avdd = [[TransparentAlert alloc]initWithTitle:[NSString stringWithFormat:@"Link For:\n%@",[path lastPathComponent]] message:link completionBlock:^(NSUInteger buttonIndex, UIAlertView *alertView) {
                            if (buttonIndex == 1) {
                                [[UIPasteboard generalPasteboard]setString:alertView.message];
                            }
                        } cancelButtonTitle:@"OK" otherButtonTitles:@"Copy", nil];
                        [avdd show];
                        [avdd release];
                    }
                }];
            }
        } cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Download", @"Get Link", nil]autorelease];
        actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        [actionSheet showInView:self.view];
    }
    
    [_theTableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)setButtonsHidden:(BOOL)shouldHide {
    [_backButton setHidden:shouldHide];
    [_homeButton setHidden:shouldHide];
}

- (void)goHome {
    _navBar.topItem.title = @"/";
    [self loadContentsOfDirectory:@"/"];
    [self refreshStateWithAnimationStyle:UITableViewRowAnimationRight];
}

- (void)goBackDir {
    _navBar.topItem.title = [_navBar.topItem.title stringByDeletingLastPathComponent];
    [self loadContentsOfDirectory:[_navBar.topItem.title fhs_normalize]];
    [self refreshStateWithAnimationStyle:UITableViewRowAnimationRight];
}

- (void)refreshStateWithAnimationStyle:(UITableViewRowAnimation)animation {
    [self loadContentsOfDirectory:[_navBar.topItem.title fhs_normalize]];
    [_theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:animation];

    if (_navBar.topItem.title.length > 1) {
        [self setButtonsHidden:NO];
    } else {
        [self setButtonsHidden:YES];
    }
    
    [_pull finishedLoading];
}

- (void)close {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [DroppinBadassBlocks cancel];
    [self dismissModalViewControllerAnimated:YES];
}

- (void)dealloc {
    [self setTheTableView:nil];
    [self setHomeButton:nil];
    [self setBackButton:nil];
    [self setNavBar:nil];
    [self setPull:nil];
    [self setCurrentPathItems:nil];
    [self setCursor:nil];
    [super dealloc];
}

@end
