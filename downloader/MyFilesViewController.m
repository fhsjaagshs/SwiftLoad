//
//  MyFilesViewController.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 8/11/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//


#import "MyFilesViewController.h"
#import "SwiftLoadCell.h"

static NSString *CellIdentifier = @"Cell";

@interface MyFilesViewController () <UITableViewDelegate, UITableViewDataSource, HamburgerViewDelegate, ContentOffsetWatchdogDelegate, SwipeCellDelegate>

// Content Offset Watchdog
@property (nonatomic, strong) ContentOffsetWatchdog *watchdog;

// Copy/Cut/Paste
@property (nonatomic, strong) NSMutableArray *copiedList;
@property (nonatomic, assign) BOOL isCut;

@property (nonatomic, strong) NSMutableArray *filelist;

@property (nonatomic, strong) UIBarButtonItem *editButton;
@property (nonatomic, strong) UITableView *theTableView;
@property (nonatomic, strong) UINavigationBar *navBar;
@property (nonatomic, strong) UIButton *theCopyAndPasteButton;

@property (nonatomic, strong) SwipeCell *currentlySwipedCell;

@property (nonatomic, strong) UIDocumentInteractionController *docController;

@end

@implementation MyFilesViewController

- (void)loadView {
    [super loadView];
    
    CGRect screenBounds = [[UIScreen mainScreen]bounds];
    
    HamburgerButtonItem *hamburger = [HamburgerButtonItem itemWithView:self.view];
    [hamburger setDelegate:self];

    self.navBar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 20+44)];
    _navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"/"];
    _editButton = [[UIBarButtonItem alloc]initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered target:self action:@selector(editTable)];
    topItem.rightBarButtonItem = _editButton;
    topItem.leftBarButtonItem = hamburger;
    [_navBar pushNavigationItem:topItem animated:YES];
    [self.view addSubview:_navBar];
    
    self.theTableView = [[UITableView alloc]initWithFrame:screenBounds style:UITableViewStylePlain];
    _theTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _theTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _theTableView.dataSource = self;
    _theTableView.delegate = self;
    _theTableView.contentInset = UIEdgeInsetsMake(20+44, 0, 0, 0);
    _theTableView.scrollIndicatorInsets = _theTableView.contentInset;
    _theTableView.separatorInset = UIEdgeInsetsZero;
    [self.view addSubview:_theTableView];
    
    [self.view bringSubviewToFront:_navBar];
    
    self.theCopyAndPasteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _theCopyAndPasteButton.frame = CGRectMake(screenBounds.size.width-41, 20+49, 36, 36);
    _theCopyAndPasteButton.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.6f];
    _theCopyAndPasteButton.layer.cornerRadius = 7;
    _theCopyAndPasteButton.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
    [_theCopyAndPasteButton setImage:[UIImage imageNamed:@"clipboard"] forState:UIControlStateNormal];
    [_theCopyAndPasteButton addTarget:self action:@selector(showCopyPasteController) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_theCopyAndPasteButton];
    [_theCopyAndPasteButton setHidden:YES];
    
    self.watchdog = [ContentOffsetWatchdog watchdogWithScrollView:_theTableView];
    _watchdog.delegate = self;
    _watchdog.mode = WatchdogModeNormal;
    [_watchdog setInitialText:@"Pull to Create File"];
    [_watchdog setTrippedText:@"Release to Create File"];
    
    [kAppDelegate setManagerCurrentDir:kDocsDir];
    
    self.watchdogCanGo = YES;
    
    self.view.opaque = YES;
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(copiedListChanged:) name:kCopyListChangedNotification object:nil];
    
    __weak MyFilesViewController *weakself = self;
    
    [[FilesystemMonitor sharedMonitor]setChangedHandler:^{
        [weakself.filelist removeAllObjects];
        [weakself.theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    }];
    
    [[FilesystemMonitor sharedMonitor]startMonitoringDirectory:kDocsDir];
}

- (void)hamburgerCellWasSelectedAtIndex:(int)index {
    if (index == 0) {
        UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"Enter URL to Download" message:nil completionBlock:^(NSUInteger buttonIndex, UIAlertView *alertView) {
            if (buttonIndex == 1) {
                NSString *urlString = [alertView textFieldAtIndex:0].text;
                [[NSUserDefaults standardUserDefaults]setObject:urlString forKey:@"myDefaults"];
                [kAppDelegate downloadFile:urlString];
            }
        } cancelButtonTitle:@"Cancel" otherButtonTitles:@"Download", nil];
        av.alertViewStyle = UIAlertViewStylePlainTextInput;
        
        UITextField *tv = [av textFieldAtIndex:0];
        tv.returnKeyType = UIReturnKeyDone;
        tv.autocapitalizationType = UITextAutocapitalizationTypeNone;
        tv.autocorrectionType = UITextAutocorrectionTypeNo;
        tv.placeholder = @"Paste URL here...";
        tv.clearButtonMode = UITextFieldViewModeWhileEditing;
        tv.text = [[NSUserDefaults standardUserDefaults]objectForKey:@"myDefaults"];
        
        [av show];
    } else if (index == 1) {
        [self presentViewController:[WebDAVViewController viewControllerWhite] animated:YES completion:nil];
    } else if (index == 2) {
        [self presentViewController:[DropboxBrowserViewController viewControllerWhite] animated:YES completion:nil];
    } else if (index == 3) {
        [self presentViewController:[SettingsView viewControllerWhite] animated:YES completion:nil];
    } else if (index == 4) {
        kAppDelegate.openFile = kAppDelegate.nowPlayingFile;
        [self presentViewController:[AudioPlayerViewController viewControllerWhite] animated:YES completion:nil];
    }
}

- (void)copiedListChanged:(NSNotification *)notif {
    if (_copiedList.count > 0) {
        NSDictionary *changeDict = [NSDictionary dictionaryWithDictionary:(NSDictionary *)(notif.object)];
        _copiedList[[_copiedList indexOfObject:changeDict[@"old"]]] = changeDict[@"new"];
    }
}

- (void)copyFilesWithIsCut:(BOOL)isCut {
    self.copiedList = [NSMutableArray array];
    
    self.isCut = isCut;
    
    for (NSIndexPath *indexPath in _theTableView.indexPathsForSelectedRows) {
        [_theTableView deselectRowAtIndexPath:indexPath animated:YES];
        NSString *currentPath = [[kAppDelegate managerCurrentDir]stringByAppendingPathComponent:_filelist[indexPath.row]];
        [_copiedList addObject:currentPath];
    }
}

- (void)deleteSelectedFiles {
    [[FilesystemMonitor sharedMonitor]invalidate];

    for (NSIndexPath *indexPath in _theTableView.indexPathsForSelectedRows) {
        NSString *filename = _filelist[indexPath.row];
        [_filelist removeObjectAtIndex:indexPath.row];
        NSString *currentPath = [[kAppDelegate managerCurrentDir]stringByAppendingPathComponent:filename];
        [[NSFileManager defaultManager]removeItemAtPath:currentPath error:nil];
    }

    [_theTableView beginUpdates];
    [_theTableView deleteRowsAtIndexPaths:_theTableView.indexPathsForSelectedRows withRowAnimation:UITableViewRowAnimationRight];
    [_theTableView endUpdates];
    
    for (NSIndexPath *indexPath in _theTableView.indexPathsForSelectedRows) {
        [_theTableView deselectRowAtIndexPath:indexPath animated:NO];
    }
    
    [[FilesystemMonitor sharedMonitor]startMonitoringDirectory:[kAppDelegate managerCurrentDir]];
    
    [self updateCopyButtonState];
}

- (void)pasteInLocation:(NSString *)location {
    
    for (NSString *oldPath in _copiedList) {
        NSString *newPath = getNonConflictingFilePathForPath([location stringByAppendingPathComponent:oldPath.lastPathComponent]);
        
        if (_isCut) {
            [[NSFileManager defaultManager]moveItemAtPath:oldPath toPath:newPath error:nil];
            if ([oldPath isEqualToString:[kAppDelegate nowPlayingFile]]) {
                [kAppDelegate setNowPlayingFile:newPath];
            }
        } else {
            [[NSFileManager defaultManager]copyItemAtPath:oldPath toPath:newPath error:nil];
        }
    }
    
    [_copiedList removeAllObjects];
    
    [self updateCopyButtonState];
}

- (void)showCopyPasteController {
    __weak MyFilesViewController *weakself = self;
    UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:nil completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
        
        NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
        
        if ([title isEqualToString:@"Copy"]) {
            [weakself copyFilesWithIsCut:NO];
        } else if ([title isEqualToString:@"Cut"]) {
            [weakself copyFilesWithIsCut:YES];
        } else if ([title isEqualToString:@"Paste"]) {
            [weakself pasteInLocation:[kAppDelegate managerCurrentDir]];
        } else if ([title isEqualToString:@"Delete"]) {
            UIActionSheet *deleteConfirmation = [[UIActionSheet alloc]initWithTitle:@"Are you Sure?" completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
                if (buttonIndex == 0) {
                    [weakself deleteSelectedFiles];
                }
            } cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles:nil];
            deleteConfirmation.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
            [deleteConfirmation showInView:self.view];
        }
        
        [weakself updateCopyButtonState];
    } cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    
    if (_copiedList.count == 0) {
        [actionSheet addButtonWithTitle:@"Copy"];
        [actionSheet addButtonWithTitle:@"Cut"];
        [actionSheet addButtonWithTitle:@"Delete"];
    } else {
        [actionSheet addButtonWithTitle:@"Paste"];
    }
    
    [actionSheet addButtonWithTitle:@"Cancel"];
    
    actionSheet.cancelButtonIndex = actionSheet.numberOfButtons-1;
    
    [actionSheet showInView:self.view];
}

- (void)updateCopyButtonState {
    
    if (!_theTableView.editing) {
        _theCopyAndPasteButton.hidden = YES;
        return;
    }
    
    BOOL persCLGT = (_theTableView.indexPathsForSelectedRows.count > 0);
    BOOL CLGT = (_copiedList.count > 0);
    BOOL shouldUnhide = ((persCLGT || CLGT) || (persCLGT && CLGT));
    
    _theCopyAndPasteButton.hidden = !shouldUnhide;
}

- (void)reindexFilelistIfNecessary {
    if (_filelist.count == 0) {
        @autoreleasepool {
            NSString *currentDir = [kAppDelegate managerCurrentDir];
            NSString *docsDir = kDocsDir;
            
            NSArray *all = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:currentDir error:nil];
            
            self.filelist = [NSMutableArray arrayWithCapacity:all.count];
            
            NSMutableArray *dirs = [NSMutableArray array];
            NSMutableArray *files = [NSMutableArray array];
            
            for (NSString *filename in all) {
                NSString *full = [currentDir stringByAppendingPathComponent:filename];
                
                if (isDirectory(full)) {
                    if ([currentDir isEqualToString:docsDir]) {
                        if (![filename isEqualToString:@"Inbox"]) {
                            [dirs addObject:filename];
                        }
                    } else {
                        [dirs addObject:filename];
                    }
                } else {
                    [files addObject:filename];
                }
            }
            
            [dirs sortUsingSelector:@selector(caseInsensitiveCompare:)];
            [files sortUsingSelector:@selector(caseInsensitiveCompare:)];
            
            [_filelist addObjectsFromArray:dirs];
            [_filelist addObjectsFromArray:files];
        }
    }
}

- (void)showFileCreationDialogue {
    UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"Create File or Directory" message:@"" completionBlock:^(NSUInteger buttonIndex, UIAlertView *alertView) {
        NSString *thingToBeCreated = getNonConflictingFilePathForPath([[kAppDelegate managerCurrentDir]stringByAppendingPathComponent:[alertView textFieldAtIndex:0].text]);
        
        if (buttonIndex == 1) {
            [[NSFileManager defaultManager]createFileAtPath:thingToBeCreated contents:nil attributes:nil];
        } else if (buttonIndex == 2) {
            [[NSFileManager defaultManager]createDirectoryAtPath:thingToBeCreated withIntermediateDirectories:NO attributes:nil error:nil];
        }
    } cancelButtonTitle:@"Cancel" otherButtonTitles:@"Create File", @"Create Folder", nil];
    av.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    UITextField *tv = [av textFieldAtIndex:0];
    tv.returnKeyType = UIReturnKeyDone;
    tv.autocapitalizationType = UITextAutocapitalizationTypeNone;
    tv.autocorrectionType = UITextAutocorrectionTypeNo;
    tv.placeholder = @"Type a filename here...";
    tv.clearButtonMode = UITextFieldViewModeWhileEditing;

    [av show];
}

- (void)goBackDir {
    [_currentlySwipedCell hideWithAnimation:NO];

    _navBar.topItem.title = [_navBar.topItem.title stringByDeletingLastPathComponent];
    [kAppDelegate setManagerCurrentDir:[kDocsDir stringByAppendingPathComponent:_navBar.topItem.title]];
    
    [[FilesystemMonitor sharedMonitor]startMonitoringDirectory:[kAppDelegate managerCurrentDir]];
}

- (BOOL)shouldTripWatchdog:(ContentOffsetWatchdog *)watchdog {
    
    if (_theTableView.editing) {
        return YES;
    }
    
    return (![[kAppDelegate managerCurrentDir]isEqualToString:kDocsDir] && _watchdogCanGo);
}

- (void)watchdogWasTripped:(ContentOffsetWatchdog *)watchdog {
    [_watchdog resetOffset];

    if (_watchdog.mode == WatchdogModeNormal) {
        [self goBackDir];
        [_filelist removeAllObjects];
        [_theTableView reloadDataWithCoolAnimationType:CoolRefreshAnimationStyleBackward];
        self.watchdogCanGo = NO;
    } else if (_watchdog.mode == WatchdogModePullToRefresh) {
        [self showFileCreationDialogue];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    [self reindexFilelistIfNecessary];
    return _filelist.count;
}

- (void)accessoryButtonPressed:(id)sender {
    UIButton *button = (UIButton *)sender;
    CGPoint correctedPoint = [button convertPoint:button.bounds.origin toView:_theTableView];
    NSIndexPath *indexPath = [_theTableView indexPathForRowAtPoint:correctedPoint];
    NSString *file = [[kAppDelegate managerCurrentDir]stringByAppendingPathComponent:_filelist[indexPath.row]];
    
    [kAppDelegate setOpenFile:file];

    FileInfoViewController *info = [FileInfoViewController viewController];
    info.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:info animated:YES completion:nil];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    [self reindexFilelistIfNecessary];
    
    SwipeCell *cell = (SwipeCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[SwipeCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        [cell.disclosureButton addTarget:self action:@selector(accessoryButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    cell.delegate = self;
    
    NSString *filesObjectAtIndex = _filelist[indexPath.row];
    NSString *file = [[kAppDelegate managerCurrentDir]stringByAppendingPathComponent:filesObjectAtIndex];
    
    cell.textLabel.text = filesObjectAtIndex;

    if (isDirectory(file)) {
        cell.detailTextLabel.text = @"Directory";
        cell.imageView.image = [UIImage imageNamed:@"folder_icon"];
        cell.swipeEnabled = NO;
        cell.backgroundView = nil;
    } else {
        cell.imageView.image = [UIImage imageNamed:@"file_icon"];
        cell.swipeEnabled = !_theTableView.editing;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@",[file.pathExtension.lowercaseString isEqualToString:@"zip"]?@"Archive":@"File",[NSString fileSizePrettify:fileSize(file)]];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    AppDelegate *ad = kAppDelegate;
    
    NSString *file = [ad.managerCurrentDir stringByAppendingPathComponent:_filelist[indexPath.row]];

    if (isDirectory(file)) {
        _navBar.topItem.title = [_navBar.topItem.title stringByAppendingPathComponent:file.lastPathComponent];
        
        [ad setManagerCurrentDir:file];
        
        [[FilesystemMonitor sharedMonitor]startMonitoringDirectory:ad.managerCurrentDir];
        
        [_filelist removeAllObjects];
        [_theTableView reloadDataWithCoolAnimationType:CoolRefreshAnimationStyleForward];
        [_theTableView flashScrollIndicators];
    } else if ([file.pathExtension.lowercaseString isEqualToString:@"zip"]) {
        ad.openFile = file;
        
        UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:[NSString stringWithFormat:@"What would you like to do with %@?",file.lastPathComponent] completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
            
            NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
            
            if ([title isEqualToString:@"Compress Copied Items"]) {
                if (_copiedList.count > 0) {
                    CompressionTask *task = [CompressionTask taskWithItems:_copiedList andZipFile:ad.openFile];
                    [[TaskController sharedController]addTask:task];
                }
                
                [_copiedList removeAllObjects];
                [self updateCopyButtonState];
                
            } else if ([title isEqualToString:@"Decompress"]) {
                if (fileSize(file) > 0) {
                    UnzippingTask *task = [UnzippingTask taskWithFile:file];
                    [[TaskController sharedController]addTask:task];
                }
            }
            
            [self updateCopyButtonState];
        } cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
        
        actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        
        if (_copiedList.count > 0) {
            [actionSheet addButtonWithTitle:@"Compress Copied Items"];
        }
        
        [actionSheet addButtonWithTitle:@"Decompress"];
        [actionSheet addButtonWithTitle:@"Cancel"];
        
        actionSheet.cancelButtonIndex = actionSheet.numberOfButtons-1;
        [actionSheet showInView:self.view];
    } else {
        
        ad.openFile = file;
        
        BOOL isHTML = [MIMEUtils isHTMLFile:file];
        
        if ([MIMEUtils isAudioFile:file]) {
            AudioPlayerViewController *audio = [AudioPlayerViewController viewController];
            audio.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
            [self presentViewController:audio animated:YES completion:nil];
        } else if ([MIMEUtils isImageFile:file]) {
            PictureViewController *pView = [PictureViewController viewController];
            pView.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
            [self presentViewController:pView animated:YES completion:nil];
        } else if ([MIMEUtils isTextFile:file] && !isHTML) {
            TextEditorViewController *textEditor = [TextEditorViewController viewController];
            textEditor.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
            [self presentViewController:textEditor animated:YES completion:nil];
        } else if ([MIMEUtils isVideoFile:file]) {
            MoviePlayerViewController *moviePlayer = [MoviePlayerViewController viewController];
            moviePlayer.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
            [self presentViewController:moviePlayer animated:YES completion:nil];
        } else if ([MIMEUtils isDocumentFile:file] || isHTML) {
            DocumentViewController *detail = [DocumentViewController viewController];
            detail.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
            [self presentViewController:detail animated:YES completion:nil];
        } else {
            NSString *message = [NSString stringWithFormat:@"Swift cannot determine which editor to open \"%@\" in. Please select which viewer to open it in.",file.lastPathComponent];
            
            UIActionSheet *sheet = [[UIActionSheet alloc]initWithTitle:message completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
                [self actionSheetAction:actionSheet buttonIndex:buttonIndex];
            } cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Open in Text Editor", @"Open in Movie Player", @"Open in Picture Viewer", @"Open in Audio Player", @"Open in Document Viewer", @"Open In...", nil];
            
            sheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
            [sheet showInView:self.view];
        }
    }
    [_theTableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [_currentlySwipedCell hideWithAnimation:YES];
    
    if (_theTableView.editing) {
        [_theTableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        [self updateCopyButtonState];
        return nil;
    }
    return indexPath;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_theTableView.editing) {
        [_theTableView deselectRowAtIndexPath:indexPath animated:YES];
        [self updateCopyButtonState];
        return nil;
    }
    return indexPath;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_theTableView.editing) {
        return YES;
    } else {
        [self reindexFilelistIfNecessary];
        NSString *file = [[kAppDelegate managerCurrentDir]stringByAppendingPathComponent:_filelist[indexPath.row]];
        return isDirectory(file);
    }
}

- (void)editTable {
    [_currentlySwipedCell hideWithAnimation:NO];
    [self reindexFilelistIfNecessary];
    
    _watchdog.mode = _theTableView.editing?WatchdogModeNormal:WatchdogModePullToRefresh;
    _theTableView.allowsMultipleSelectionDuringEditing = !_theTableView.editing;
    _editButton.title = _theTableView.editing?@"Edit":@"Done";
    [_theTableView setEditing:!_theTableView.editing animated:YES];
    
    for (SwipeCell *cell in _theTableView.visibleCells) {
        cell.swipeEnabled = !_theTableView.editing;
    }
    
    [self updateCopyButtonState];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath) {
        return UITableViewCellEditingStyleNone;
    }
    
    if (_theTableView.editing) {
        return UITableViewCellEditingStyleNone;
    }

    [self reindexFilelistIfNecessary];
    
    NSString *file = [[kAppDelegate managerCurrentDir]stringByAppendingPathComponent:_filelist[indexPath.row]];
    
    return isDirectory(file)?UITableViewCellEditingStyleDelete:UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        __weak MyFilesViewController *weakself = self;
        
        NSString *file = _filelist[indexPath.row];
        
        NSString *message = [NSString stringWithFormat:@"Are you sure you want to delete %@?",file];
        
        UIActionSheet *popupQuery = [[UIActionSheet alloc]initWithTitle:message completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
            
            if (buttonIndex == actionSheet.destructiveButtonIndex) {
                
                [[FilesystemMonitor sharedMonitor]invalidate];
                
                NSString *removePath = [[kAppDelegate managerCurrentDir]stringByAppendingPathComponent:file];
                
                [[NSFileManager defaultManager]removeItemAtPath:removePath error:nil];
                
                [weakself.filelist removeObjectAtIndex:indexPath.row];
                [[NSFileManager defaultManager]removeItemAtPath:file error:nil];
                
                [weakself.theTableView beginUpdates];
                [weakself.theTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
                [weakself.theTableView endUpdates];
                
                [[FilesystemMonitor sharedMonitor]startMonitoringDirectory:[kAppDelegate managerCurrentDir]];
            }
            
        } cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"I'm sure, Delete" otherButtonTitles:nil];
        popupQuery.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        [popupQuery showInView:self.view];
    }
}

- (void)actionSheetAction:(UIActionSheet *)actionSheet buttonIndex:(NSUInteger)buttonIndex {
    
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }
    
    if (buttonIndex == 0) {
        TextEditorViewController *textEditor = [TextEditorViewController viewController];
        textEditor.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [self presentViewController:textEditor animated:YES completion:nil];
    } else if (buttonIndex == 1) {
        MoviePlayerViewController *moviePlayer = [MoviePlayerViewController viewController];
        moviePlayer.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [self presentViewController:moviePlayer animated:YES completion:nil];
    } else if (buttonIndex == 2) {
        PictureViewController *pView = [PictureViewController viewController];
        pView.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [self presentViewController:pView animated:YES completion:nil];
    } else if (buttonIndex == 3) {
        AudioPlayerViewController *acontroller = [AudioPlayerViewController viewController];
        acontroller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [self presentViewController:acontroller animated:YES completion:nil];
    } else if (buttonIndex == 4) {
        DocumentViewController *vcontroller = [DocumentViewController viewController];
        vcontroller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [self presentViewController:vcontroller animated:YES completion:nil];
    } else if (buttonIndex == 5) {
        NSString *file = [kAppDelegate openFile];
        self.docController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:file]];

        BOOL opened = NO;
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            opened = [_docController presentOpenInMenuFromRect:_currentlySwipedCell.frame inView:_theTableView animated:YES];
        } else {
            opened = [_docController presentOpenInMenuFromRect:self.view.frame inView:self.view animated:YES];
        }
        
        if (!opened) {
            [UIAlertView showAlertWithTitle:@"No External Viewers" andMessage:[NSString stringWithFormat:@"No installed applications are capable of opening %@.",file.lastPathComponent]];
        }
    }
    [_currentlySwipedCell hideWithAnimation:YES];
}

- (void)swipeCellWillReveal:(SwipeCell *)cell {
    if (_currentlySwipedCell) {
        __weak MyFilesViewController *weakself = self;
        [_currentlySwipedCell hideWithAnimation:YES andCompletionHandler:^{
            weakself.currentlySwipedCell = cell;
        }];
    } else {
        self.currentlySwipedCell = cell;
    }
}

- (void)swipeCellDidHide:(SwipeCell *)cell {
    self.currentlySwipedCell = nil;
}

- (UIView *)backgroundViewForSwipeCell:(SwipeCell *)cell {
    UIView *backgroundView = [[UIView alloc]initWithFrame:CGRectMake(_theTableView.frame.origin.x, _theTableView.frame.origin.y, _theTableView.frame.size.width, _theTableView.rowHeight)];
    backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    backgroundView.backgroundColor = [UIColor darkGrayColor];

    NSArray *buttonData = @[@"action", @"dropbox", @"bluetooth", @"paperclip", @"delete"];
    
    NSString *filePath = [[kAppDelegate managerCurrentDir]stringByAppendingPathComponent:cell.textLabel.text];
    BOOL disableDelete = [filePath isEqualToString:[kAppDelegate nowPlayingFile]];
    
    for (int index = 0; index < buttonData.count; index++) {
        @autoreleasepool {
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.frame = CGRectMake(index*((backgroundView.bounds.size.width)/buttonData.count), 0, ((backgroundView.bounds.size.width)/buttonData.count), backgroundView.bounds.size.height);
            button.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
            
            NSString *imageName = buttonData[index];

            if ([imageName isEqualToString:@"bluetooth"] && [[BTManager shared]isTransferring]) {
                button.enabled = NO;
            } else if (disableDelete && [imageName isEqualToString:@"delete"]) {
                button.enabled = NO;
            }
    
            UIImage *grayImage = [UIImage imageNamed:imageName];
            [button setTag:index+1];
            [button addTarget:self action:@selector(touchUpInsideAction:) forControlEvents:UIControlEventTouchUpInside];
            [button setImage:grayImage forState:UIControlStateNormal];
            [backgroundView addSubview:button];
        }
    }
    return backgroundView;
}

- (void)touchUpInsideAction:(UIButton *)button {

    AppDelegate *ad = kAppDelegate;
    
    NSString *file = [ad.managerCurrentDir stringByAppendingPathComponent:_currentlySwipedCell.textLabel.text];
    ad.openFile = file;
    
    long number = button.tag-1;
    
    if (number == 0) {
        NSString *message = [NSString stringWithFormat:@"What would you like to do with %@?",file.lastPathComponent];
        
        UIActionSheet *popupQuery = [[UIActionSheet alloc]initWithTitle:message completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
            [self actionSheetAction:actionSheet buttonIndex:buttonIndex];
        } cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Open In Text Editor", @"Open In Movie Player", @"Open In Picture Viewer", @"Open In Audio Player", @"Open In Document Viewer", @"Open In...", nil];
        popupQuery.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            [popupQuery showFromRect:[_currentlySwipedCell.backgroundView convertRect:button.frame toView:self.view] inView:self.view animated:YES];
        } else {
            [popupQuery showInView:self.view];
            [_currentlySwipedCell hideWithAnimation:YES];
        }
    } else if (number == 1) {
        DropboxUpload *task = [DropboxUpload uploadWithFile:file];
        [[TaskController sharedController]addTask:task];
        [_currentlySwipedCell hideWithAnimation:YES];
    } else if (number == 2) {
        [[BTManager shared]sendFileAtPath:file];
        [_currentlySwipedCell hideWithAnimation:YES];
    } else if (number == 3) {
        [ad sendFileInEmail:file];
        [_currentlySwipedCell hideWithAnimation:YES];
    } else if (number == 4) {
        
        __weak MyFilesViewController *weakself = self;
        
        NSString *message = [NSString stringWithFormat:@"Are you sure you want to delete %@?",file.lastPathComponent];
        
        UIActionSheet *popupQuery = [[UIActionSheet alloc]initWithTitle:message completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
            
            if (buttonIndex == actionSheet.destructiveButtonIndex) {
                
                [[FilesystemMonitor sharedMonitor]invalidate];
                
                NSIndexPath *indexPath = [_theTableView indexPathForCell:_currentlySwipedCell];

                [weakself.currentlySwipedCell hideWithAnimation:NO];
                
                [weakself.filelist removeObjectAtIndex:indexPath.row];
                [[NSFileManager defaultManager]removeItemAtPath:file error:nil];
                
                [weakself.theTableView beginUpdates];
                [weakself.theTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
                [weakself.theTableView endUpdates];

                [[FilesystemMonitor sharedMonitor]startMonitoringDirectory:[kAppDelegate managerCurrentDir]];
            }
            
        } cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"I'm sure, Delete" otherButtonTitles:nil];
        popupQuery.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        [popupQuery showInView:self.view];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [_currentlySwipedCell hideWithAnimation:YES];
    [(Hack *)[UIApplication sharedApplication]setShouldWatchTouches:YES];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    [(Hack *)[UIApplication sharedApplication]setShouldWatchTouches:NO];
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    [_currentlySwipedCell hideWithAnimation:NO];
    return YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [_theTableView flashScrollIndicators];
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
