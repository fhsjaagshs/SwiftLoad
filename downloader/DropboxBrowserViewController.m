//
//  DropboxBrowserViewController.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 3/30/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "DropboxBrowserViewController.h"
#import "ButtonBarView.h"
#import "CustomCellCell.h"

@interface DropboxBrowserViewController () <UITableViewDataSource, UITableViewDelegate, PullToRefreshViewDelegate>

@property (nonatomic, retain) ShadowedTableView *theTableView;
@property (nonatomic, retain) CustomButton *backButton;
@property (nonatomic, retain) CustomButton *homeButton;
@property (nonatomic, retain) ShadowedNavBar *navBar;
@property (nonatomic, retain) PullToRefreshView *pull;

@property (nonatomic, retain) NSMutableDictionary *pathContents;
@property (nonatomic, retain) NSMutableArray *currentPathItems;

@property (nonatomic, assign) int numberOfDirsToGo;

@property (nonatomic, retain) NSString *userID;
@property (nonatomic, retain) NSString *cursor;

@end

@implementation DropboxBrowserViewController

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
    bbv.frame = CGRectMake(0, 44, screenBounds.size.width, 44);
    [self.view addSubview:bbv];
    
    /*ButtonBarView *bbv = [[[ButtonBarView alloc]initWithFrame:CGRectMake(0, 44, screenBounds.size.width, 44)]autorelease];
    bbv.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:bbv];*/
    
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
    
    self.pathContents = [NSMutableDictionary dictionary];
    self.currentPathItems = [NSMutableArray array];
}

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view {
    [self.pull setState:PullToRefreshViewStateLoading];
    [self loadCachesThenUpdateFileListing];
}

- (void)loadCachesThenUpdateFileListing {
    if (_userID.length == 0) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        [DroppinBadassBlocks loadAccountInfoWithCompletionBlock:^(DBAccountInfo *info, NSError *error) {
            self.userID = info.userId;
            [self loadCachesThenUpdateFileListing];
        }];
    } else {
        NSString *fileCacheName = [NSString stringWithFormat:@"dbcache-%@.plist",_userID];
        NSString *filePath = [kCachesDir stringByAppendingPathComponent:fileCacheName];
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
        
        NSString *cursor = [dict objectForKey:@"cursor"];
        NSMutableDictionary *pathContentsTemp = [dict objectForKey:@"pathContents"];
        
        if (cursor.length > 0) {
            
            self.cursor = cursor;
            
            if (pathContentsTemp.allKeys.count > 0) {
                self.pathContents = [NSMutableDictionary dictionaryWithDictionary:pathContentsTemp];
            }
        } else {
            self.cursor = nil;
        }
        
        [self updateFileListing];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    if (![[DBSession sharedSession]isLinked]) {
        [[DBSession sharedSession]linkFromController:self];
    } else {
        [self.pull setState:PullToRefreshViewStateLoading];
        [self loadCachesThenUpdateFileListing];
    }
}

- (void)cacheFiles {
    if (_userID.length == 0) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        [DroppinBadassBlocks loadAccountInfoWithCompletionBlock:^(DBAccountInfo *info, NSError *error) {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            self.userID = info.userId;
            [self cacheFiles];
        }];
    } else {
        NSString *fileCacheName = [NSString stringWithFormat:@"dbcache-%@.plist",_userID];
        NSString *filePath = [kCachesDir stringByAppendingPathComponent:fileCacheName];
        NSDictionary *dict = @{@"cursor": (_cursor.length == 0)?@"":_cursor, @"pathContents": _pathContents};
        [dict writeToFile:filePath atomically:YES];
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
                [_pathContents removeAllObjects];
                [self cacheFiles];
            }

            self.cursor = cursor;
            
            for (DBDeltaEntry *entry in entries) {
                if (entry.metadata == nil) {
                    [self.pathContents removeObjectForKey:entry.lowercasePath];
                } else {
                    DBMetadata *item = entry.metadata;
                    
                    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                    [dict setObject:item.isDirectory?NSFileTypeDirectory:NSFileTypeRegular forKey:NSFileType];
                    [dict setObject:item.filename forKey:NSFileName];
                    [dict setObject:[NSNumber numberWithLongLong:item.totalBytes] forKey:NSFileSize];
                    [dict setObject:item.lastModifiedDate forKey:NSFileModificationDate];
                    [dict setObject:item.isDirectory?[item.path scr_stringByFixingForURL]:item.path forKey:NSFileDBPath];
                    [self.pathContents setObject:dict forKey:entry.lowercasePath];
                }
            }
            
            if (hasMore) {
                NSLog(@"Continuing");
                [self updateFileListing];
            } else {
                NSLog(@"done");
                [self cacheFiles];
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
    return [self.currentPathItems count];
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
    
    NSDictionary *fileDict = [self.currentPathItems objectAtIndex:indexPath.row];
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

    NSDictionary *fileDict = [self.currentPathItems objectAtIndex:indexPath.row];
    NSString *filename = [fileDict objectForKey:NSFileName];
    
    NSString *filetype = (NSString *)[fileDict objectForKey:NSFileType];
    
    if ([filetype isEqualToString:(NSString *)NSFileTypeDirectory]) {
        self.navBar.topItem.title = [fileDict objectForKey:NSFileDBPath];
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
                        CustomAlertView *avdd = [[CustomAlertView alloc]initWithTitle:[NSString stringWithFormat:@"Link For:\n%@",[path lastPathComponent]] message:link completionBlock:^(NSUInteger buttonIndex, UIAlertView *alertView) {
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
    
    [self.theTableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)setButtonsHidden:(BOOL)shouldHide {
    [self.backButton setHidden:shouldHide];
    [self.homeButton setHidden:shouldHide];
}

- (void)goHome {
    self.navBar.topItem.title = @"/";
    [self refreshStateWithAnimationStyle:UITableViewRowAnimationRight];
}

- (void)goBackDir {
    self.navBar.topItem.title = [self.navBar.topItem.title stringByDeletingLastPathComponent];
    [self refreshStateWithAnimationStyle:UITableViewRowAnimationRight];
}

- (void)refreshStateWithAnimationStyle:(UITableViewRowAnimation)animation {
    [self updateCurrentDirContentsWithPath:_navBar.topItem.title];
    [self.theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:animation];

    if (_navBar.topItem.title.length > 1) {
        [self setButtonsHidden:NO];
    } else {
        [self setButtonsHidden:YES];
    }
    
    [_pull finishedLoading];
}

- (int)getNumberOfPathComponents:(NSString *)path {
    
    NSMutableArray *components = [NSMutableArray arrayWithArray:[path componentsSeparatedByString:@"/"]];
    
    for (NSString *string in [[components mutableCopy]autorelease]) {
        if (string.length == 0) {
            [components removeObject:string];
        }
    }
    
    return components.count+1;
}

- (void)updateCurrentDirContentsWithPath:(NSString *)path {
    [self.currentPathItems removeAllObjects];
    self.currentPathItems = [NSMutableArray array];
    
    NSString *pathy = [path lowercaseString];
    
    int pathyPathCount = [self getNumberOfPathComponents:pathy];
    
    NSMutableArray *workedArray = [NSMutableArray array];
    
    for (NSString *lowercasePath in self.pathContents.allKeys) {
        if ([lowercasePath hasPrefix:pathy]) {
            int maxComponents = pathyPathCount+1;
            
            if ([self getNumberOfPathComponents:lowercasePath] == maxComponents) {
                [workedArray addObject:lowercasePath];
            }
        }
    }
    
    workedArray = [[[workedArray sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]mutableCopy]autorelease];
    
    for (id obj in workedArray) {
        [self.currentPathItems addObject:[self.pathContents objectForKey:obj]];
    }
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
    [self setPathContents:nil];
    [self setCurrentPathItems:nil];
    [self setUserID:nil];
    [self setCursor:nil];
    [super dealloc];
}

@end
