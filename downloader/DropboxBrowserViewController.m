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
}

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view {
    [self.pathContents removeAllObjects];
    [self loadRoot];
}

- (void)viewDidAppear:(BOOL)animated {
    if (![[DBSession sharedSession]isLinked]) {
        [[DBSession sharedSession]linkFromController:self];
    } else {
        if (self.pathContents.count == 0) {
            [self loadRoot];
        }
    }
}

- (void)parseMetadata:(DBMetadata *)metadata {
    if (self.pathContents.count == 0) {
        self.pathContents = [NSMutableDictionary dictionary];
    }
    
    NSMutableArray *items = [NSMutableArray array];
    
    for (DBMetadata *item in metadata.contents) {
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        
        if (item.isDirectory) {
            self.numberOfDirsToGo += 1;
            [dict setObject:[item.path scr_stringByFixingForURL] forKey:NSFileDBPath];
            [self loadFilesForDBPath:[item.path scr_stringByFixingForURL]];
        }
        
        [dict setObject:item.isDirectory?NSFileTypeDirectory:NSFileTypeRegular forKey:NSFileType];
        [dict setObject:item.filename forKey:NSFileName];
        [dict setObject:[NSNumber numberWithLongLong:item.totalBytes] forKey:NSFileSize];
        [dict setObject:item.lastModifiedDate forKey:NSFileModificationDate];
        [dict setObject:item.path forKey:NSFileDBPath];
        
        [items addObject:dict];
    }
    
    self.numberOfDirsToGo -= 1;
    
    [self.pathContents setObject:items forKey:[metadata.path scr_stringByFixingForURL]];
}

- (void)loadRoot {
    self.numberOfDirsToGo = 1;
    
    [self.pull setState:PullToRefreshViewStateLoading];
    
    [DroppinBadassBlocks loadMetadata:@"/" withCompletionBlock:^(DBMetadata *metadata, NSError *error) {
        [self parseMetadata:metadata];
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (YES) {
            if (self.numberOfDirsToGo == 0) {
                [self finishedLoadingMetadata];
                break;
            }
        }
    });
}

- (void)loadFilesForDBPath:(NSString *)path {
    [DroppinBadassBlocks loadMetadata:path withCompletionBlock:^(DBMetadata *metadata, NSError *error) {
        [self parseMetadata:metadata];
    }];
}

- (void)finishedLoadingMetadata {
    [self.pull finishedLoading];
    [self refreshStateWithAnimationStyle:UITableViewRowAnimationFade];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self getFiles]count];
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
    
    NSDictionary *fileDict = [[self getFiles]objectAtIndex:indexPath.row];
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
    
    NSDictionary *fileDict = [[self getFiles]objectAtIndex:indexPath.row];
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
                
                [DroppinBadassBlocks loadFile:[fileDict objectForKey:NSFileDBPath] intoPath:[kDocsDir stringByAppendingPathComponent:filename] withCompletionBlock:^(DBMetadata *metadata, NSError *error) {
                    if (error) {
                        [kAppDelegate showFailedAlertForFilename:metadata.filename];
                    } else {
                        [kAppDelegate showFinishedAlertForFilename:metadata.filename];
                    }
                } andProgressBlock:^(CGFloat progress) {
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
    self.navBar.topItem.title = [[self.navBar.topItem.title stringByDeletingLastPathComponent]scr_stringByFixingForURL];
    [self refreshStateWithAnimationStyle:UITableViewRowAnimationRight];
}

- (void)refreshStateWithAnimationStyle:(UITableViewRowAnimation)animation {
    [self.theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:animation];

    if (self.navBar.topItem.title.length > 1) {
        [self setButtonsHidden:NO];
    } else {
        [self setButtonsHidden:YES];
    }
}

- (NSArray *)getFiles {
    return [self.pathContents objectForKey:[self.navBar.topItem.title scr_stringByFixingForURL]];
}

- (void)close {
    [self dismissModalViewControllerAnimated:YES];
}

@end
