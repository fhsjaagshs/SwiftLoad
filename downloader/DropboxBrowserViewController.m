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
#import <DropboxSDK/DropboxSDK.h>

@interface DropboxBrowserViewController () <UITableViewDataSource, UITableViewDelegate, PullToRefreshViewDelegate>

@property (nonatomic, retain) ShadowedTableView *theTableView;
@property (nonatomic, retain) CustomButton *backButton;
@property (nonatomic, retain) CustomButton *homeButton;
@property (nonatomic, retain) CustomNavBar *navBar;
@property (nonatomic, retain) PullToRefreshView *pull;

@property (nonatomic, retain) NSMutableDictionary *pathContents;
@property (nonatomic, retain) NSMutableArray *currentPathItems;

@property (nonatomic, assign) int numberOfDirsToGo;

@end

@implementation DropboxBrowserViewController

- (void)loadView {
    [super loadView];
    
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    
    self.view = [[[HatchedView alloc]initWithFrame:screenBounds]autorelease];
    
    self.navBar = [[[CustomNavBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)]autorelease];
    self.navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[[UINavigationItem alloc]initWithTitle:@"/"]autorelease];
    topItem.rightBarButtonItem = nil;
    topItem.leftBarButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)]autorelease];
    [self.navBar pushNavigationItem:topItem animated:YES];
    [self.view addSubview:self.navBar];
    
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
    [self.view addSubview:self.theTableView];
    
    self.pull = [[[PullToRefreshView alloc]initWithScrollView:self.theTableView]autorelease];
    [self.pull setDelegate:self];
    [self.theTableView addSubview:self.pull];
    NSUserDefaultsOFKKill(@"DBCursor");
}

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view {
    [self.pull setState:PullToRefreshViewStateLoading];
    [self updateFileListing];
}

- (void)viewDidAppear:(BOOL)animated {
    if (![[DBSession sharedSession]isLinked]) {
        [[DBSession sharedSession]linkFromController:self];
    } else {
        [self.pull setState:PullToRefreshViewStateLoading];
        [self updateFileListing];
    }
}

- (void)cacheFiles {
    NSArray *credStore = [[DBSession sharedSession]userIds];
    
    NSLog(@"Creds: %@",credStore);
    
    if (credStore.count > 0) {
        NSString *userID = [credStore objectAtIndex:0];
        NSString *fileCacheName = [NSString stringWithFormat:@"dbcache-%@.plist",userID];
        NSString *filePath = [kCachesDir stringByAppendingPathComponent:fileCacheName];
        [self.pathContents writeToFile:filePath atomically:YES];
    }
}

- (void)updateFileListing {
    
    [DroppinBadassBlocks loadDelta:NSUserDefaultsOFK(@"DBCursor") withCompletionHandler:^(NSArray *entries, NSString *cursor, BOOL hasMore, BOOL shouldReset, NSError *error) {
        
        if (error) {
            NSLog(@"Error: %@",error);
        } else {
            // do the deed
            [[NSUserDefaults standardUserDefaults]setObject:cursor forKey:@"DBCursor"];
            
            if (self.pathContents.count == 0) {
                NSArray *credStore = [[DBSession sharedSession]userIds];
                
                if (credStore.count < 0) {
                    NSString *userID = [credStore objectAtIndex:0];
                    NSString *fileCacheName = [NSString stringWithFormat:@"dbcache-%@.plist",userID];
                    NSString *filePath = [kCachesDir stringByAppendingPathComponent:fileCacheName];
                    self.pathContents = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
                } else {
                    self.pathContents = [NSMutableDictionary dictionary];
                }
                
            }
            
            if (shouldReset) {
                NSLog(@"Resetting");
                [self.pathContents removeAllObjects];
            }
            
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
    
    //NSDictionary *fileDict = [[self getFiles]objectAtIndex:indexPath.row];
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
    
    //NSDictionary *fileDict = [[self getFilesForPath:self.navBar.topItem.title]objectAtIndex:indexPath.row];
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
    [self updateCurrentDirContentsWithPath:self.navBar.topItem.title];
    [self.theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:animation];

    if (self.navBar.topItem.title.length > 1) {
        [self setButtonsHidden:NO];
    } else {
        [self setButtonsHidden:YES];
    }
    
    [self.pull finishedLoading];
}

- (void)updateCurrentDirContentsWithPath:(NSString *)path {
    [self.currentPathItems removeAllObjects];
    self.currentPathItems = [NSMutableArray array];
    
    NSString *pathy = [path lowercaseString];
    
    NSMutableArray *workedArray = [NSMutableArray array];
    
    for (NSString *lowercasePath in self.pathContents.allKeys) {
        if ([lowercasePath hasPrefix:pathy]) {
            int maxComponents = [pathy pathComponents].count+1;
            if ([lowercasePath pathComponents].count <= maxComponents) {
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
    [self dismissModalViewControllerAnimated:YES];
}

@end
