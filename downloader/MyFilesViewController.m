//
//  MyFilesViewController.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 8/11/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//


#import "MyFilesViewController.h"
#import "SwiftLoadCell.h"
#import "TransparentAlert.h"

#define BOUNCE_PIXELS 5.0

static NSString *CellIdentifier = @"Cell";

@interface MyFilesViewController () <HamburgerViewDelegate>
@property (nonatomic, assign) BOOL watchdogCanGo;
@end

@implementation MyFilesViewController

- (void)loadView {
    [super loadView];
    
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    
    HamburgerButtonItem *hamburger = [HamburgerButtonItem itemWithView:self.view];
    [hamburger setDelegate:self];
    
    self.navBar = [[ShadowedNavBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)];
    _navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"/"];
    _editButton = [[UIBarButtonItem alloc]initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered target:self action:@selector(editTable)];
    topItem.rightBarButtonItem = _editButton;
    topItem.leftBarButtonItem = hamburger;
    [_navBar pushNavigationItem:topItem animated:YES];
    [self.view addSubview:_navBar];
    [self.view bringSubviewToFront:_navBar];
    
    self.theTableView = [[ShadowedTableView alloc]initWithFrame:CGRectMake(0, 44, screenBounds.size.width, screenBounds.size.height-44) style:UITableViewStylePlain];
    _theTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _theTableView.allowsMultipleSelectionDuringEditing = YES;
    _theTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _theTableView.backgroundColor = [UIColor clearColor];
    _theTableView.rowHeight = iPad?60:44;
    _theTableView.dataSource = self;
    _theTableView.delegate = self;
    _theTableView.canCancelContentTouches = NO;
    [self.view addSubview:_theTableView];
    
    self.theCopyAndPasteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _theCopyAndPasteButton.frame = CGRectMake(screenBounds.size.width-41, 49, 36, 36);
    _theCopyAndPasteButton.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.6f];
    _theCopyAndPasteButton.layer.cornerRadius = 7;
    _theCopyAndPasteButton.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
    [_theCopyAndPasteButton setImage:[UIImage imageNamed:@"clipboard"] forState:UIControlStateNormal];
    [_theCopyAndPasteButton addTarget:self action:@selector(showCopyPasteController) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_theCopyAndPasteButton];
    [_theCopyAndPasteButton setHidden:YES];
    
    ContentOffsetWatchdog *watchdog = [ContentOffsetWatchdog watchdogWithScrollView:_theTableView];
    watchdog.delegate = self;
    
    [kAppDelegate setManagerCurrentDir:kDocsDir];
    
    self.animatingSideSwipe = NO;
    self.watchdogCanGo = YES;
    
    self.view.opaque = YES;
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(copiedListChanged:) name:kCopyListChangedNotification object:nil];
    
    [[AVAudioSession sharedInstance]setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    __weak MyFilesViewController *weakself = self;
    
    [[FilesystemMonitor sharedMonitor]setChangedHandler:^{
        [weakself refreshTableViewWithAnimation:UITableViewRowAnimationFade];
    }];
    
    [[FilesystemMonitor sharedMonitor]startMonitoringDirectory:kDocsDir];
}

- (void)hamburgerCellWasSelectedAtIndex:(int)index {
    if (index == 0) {
        [[[URLInputController alloc]initWithCompletionBlock:^(NSString *url) {
            [kAppDelegate downloadFile:url];
        }]show];
    } else if (index == 1) {
        webDAVViewController *advc = [webDAVViewController viewController];
        [self presentModalViewController:advc animated:YES];
    } else if (index == 2) {
        DropboxBrowserViewController *d = [DropboxBrowserViewController viewController];
        [self presentModalViewController:d animated:YES];
    } else if (index == 3) {
        SFTPBrowserViewController *s = [SFTPBrowserViewController viewController];
        [self presentModalViewController:s animated:YES];
    } else if (index == 4) {
        SettingsView *d = [SettingsView viewController];
        [self presentModalViewController:d animated:YES];
    }
}

- (void)setWatchdogCanGoYES {
    self.watchdogCanGo = YES;
}

- (void)copiedListChanged:(NSNotification *)notif {
    if (_copiedList.count > 0) {
        NSDictionary *changeDict = [NSDictionary dictionaryWithDictionary:(NSDictionary *)(notif.object)];
        [_copiedList replaceObjectAtIndex:[_copiedList indexOfObject:[changeDict objectForKey:@"old"]] withObject:[changeDict objectForKey:@"new"]];
    }
}

- (void)copyFilesWithIsCut:(BOOL)isCut {
    if (!_copiedList) {
        self.copiedList = [NSMutableArray array];
    } else {
        [_copiedList removeAllObjects];
    }
    
    self.isCut = isCut;
    
    for (NSIndexPath *indexPath in _theTableView.indexPathsForSelectedRows) {
        [_theTableView cellForRowAtIndexPath:indexPath].selected = NO;
        NSString *filename = [_filelist objectAtIndex:indexPath.row];
        NSString *currentPath = [[kAppDelegate managerCurrentDir]stringByAppendingPathComponent:filename];
        [_copiedList addObject:currentPath];
    }
}

- (void)deleteSelectedFiles {
    for (NSIndexPath *indexPath in _theTableView.indexPathsForSelectedRows) {
        [_theTableView cellForRowAtIndexPath:indexPath].selected = NO;
        NSString *filename = [_filelist objectAtIndex:indexPath.row];
        NSString *currentPath = [[kAppDelegate managerCurrentDir]stringByAppendingPathComponent:filename];
        [[NSFileManager defaultManager]removeItemAtPath:currentPath error:nil];
    }
}

- (void)pasteInLocation:(NSString *)location {
    
    AppDelegate *ad = kAppDelegate;
    
    [ad showHUDWithTitle:_isCut?@"Moving Files...":@"Copying Files..."];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
        
            NSFileManager *fm = [[NSFileManager alloc]init];
            
            for (NSString *oldPath in _copiedList) {
                [ad setSecondaryTitleOfVisibleHUD:[oldPath lastPathComponent]];
                NSString *newPath = getNonConflictingFilePathForPath([location stringByAppendingPathComponent:[oldPath lastPathComponent]]);
                
                if (_isCut) {
                    [fm moveItemAtPath:oldPath toPath:newPath error:nil];
                    if ([oldPath isEqualToString:[kAppDelegate nowPlayingFile]]) {
                        [kAppDelegate setNowPlayingFile:newPath];
                    }
                } else {
                    [fm copyItemAtPath:oldPath toPath:newPath error:nil];
                }
            }
            
            [_copiedList removeAllObjects];

            dispatch_sync(dispatch_get_main_queue(), ^{
                @autoreleasepool {
                    [kAppDelegate hideHUD];
                    [self refreshTableViewWithAnimation:UITableViewRowAnimationFade];
                    [self updateCopyButtonState];
                }
            });
        
        }
    });
}

- (void)showCopyPasteController {
    UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:nil completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
        
        NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
        
        if ([title isEqualToString:@"Copy"]) {
            [self copyFilesWithIsCut:NO];
        } else if ([title isEqualToString:@"Cut"]) {
            [self copyFilesWithIsCut:YES];
        } else if ([title isEqualToString:@"Paste"]) {
            [self pasteInLocation:[kAppDelegate managerCurrentDir]];
        } else if ([title isEqualToString:@"Delete"]) {
            UIActionSheet *deleteConfirmation = [[UIActionSheet alloc]initWithTitle:@"Are you Sure?" completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
                if (buttonIndex == 0) {
                    [self deleteSelectedFiles];
                }
            } cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles:nil];
            deleteConfirmation.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
            [deleteConfirmation showInView:self.view];
        }
        
        [self updateCopyButtonState];
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
    
    NSLog(@"%@",_theTableView.indexPathsForSelectedRows);
    
    BOOL persCLGT = (_theTableView.indexPathsForSelectedRows.count > 0);
    BOOL CLGT = (_copiedList.count > 0);
    BOOL shouldUnhide = ((persCLGT || CLGT) || (persCLGT && CLGT));
    
    _theCopyAndPasteButton.hidden = !shouldUnhide;
}

- (void)reindexFilelist {
    if (_filelist.count == 0) {
        self.filelist = [NSMutableArray array];
        [_filelist addObjectsFromArray:[[[NSFileManager defaultManager]contentsOfDirectoryAtPath:[kAppDelegate managerCurrentDir] error:nil]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
    }
}

- (void)refreshTableViewWithAnimation:(UITableViewRowAnimation)rowAnim {
    [_filelist removeAllObjects];
    [_theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:rowAnim];
}

- (void)inflate:(NSString *)file {
    
    [[BGProcFactory sharedFactory]startProcForKey:@"inflate" andExpirationHandler:^{
        
    }];
    
    @autoreleasepool {
    
        [UIApplication sharedApplication].idleTimerDisabled = YES;
        ZipFile *unzipFile = [[ZipFile alloc]initWithFileName:file mode:ZipFileModeUnzip];
        NSArray *infos = [unzipFile listFileInZipInfos];
        
        MBProgressHUD *HUDZ = [kAppDelegate getVisibleHUD];
        
        if (HUDZ.tag != 5) {
            HUDZ = nil;
        }
        
        HUDZ.progress = 0;
        float unachivedBytes = 0;
        float filesize = 0;
        
        for (FileInZipInfo *info in infos) {
            filesize = filesize+info.length;
        }
        
        for (FileInZipInfo *info in infos) {

            [unzipFile locateFileInZip:info.name];
            NSString *dirOfZip = [file stringByDeletingLastPathComponent];
            NSString *writeLocation = [dirOfZip stringByAppendingPathComponent:info.name];
            NSString *slash = [info.name substringFromIndex:[info.name length]-1];
            
            if ([slash isEqualToString:@"/"]) {
                [[NSFileManager defaultManager]createDirectoryAtPath:writeLocation withIntermediateDirectories:NO attributes:nil error:nil];
            } else {
                if (![[NSFileManager defaultManager]fileExistsAtPath:writeLocation]) {
                    [[NSFileManager defaultManager]createFileAtPath:writeLocation contents:nil attributes:nil];
                
                    NSFileHandle *file = [NSFileHandle fileHandleForWritingAtPath:writeLocation];
            
                    ZipReadStream *read = [unzipFile readCurrentFileInZip];
                    
                    int buffSize = 1024*1024;

                    NSMutableData *buffer = [[NSMutableData alloc]initWithLength:buffSize];
                    do {
                        [buffer setLength:buffSize];
                        int bytesRead = [read readDataWithBuffer:buffer];
                        if (bytesRead == 0) {
                            break;
                        } else {
                            [buffer setLength:bytesRead];
                            [file writeData:buffer];
                            
                            unachivedBytes = unachivedBytes+bytesRead;
                            HUDZ.progress = (unachivedBytes/filesize);
                        }
                    } while (YES);
            
                    [file closeFile];
                    [read finishedReading];
                } else {
                    unachivedBytes = unachivedBytes+info.length;
                    HUDZ.progress = (unachivedBytes/filesize);
                }
            }
        }
        [unzipFile close];
        
        [kAppDelegate hideHUD];
        
        [UIApplication sharedApplication].idleTimerDisabled = NO;
        [self refreshTableViewWithAnimation:UITableViewRowAnimationNone];
        
        [[BGProcFactory sharedFactory]endProcForKey:@"inflate"];
    
    }
}

- (void)compressItems:(NSArray *)items intoZipFile:(NSString *)file {
    for (NSString *theFile in items) {
        [kAppDelegate setSecondaryTitleOfVisibleHUD:theFile.lastPathComponent];
        [self compressItem:theFile intoZipFile:file];
    }
    [kAppDelegate hideHUD];
}

- (void)compressItem:(NSString *)theFile intoZipFile:(NSString *)file {
    @autoreleasepool {
    
        [[BGProcFactory sharedFactory]startProcForKey:@"compress" andExpirationHandler:^{
            
        }];
        
        [UIApplication sharedApplication].idleTimerDisabled = YES;
        NSString *currentDir = [kAppDelegate managerCurrentDir];
        
        BOOL isDirMe;    
        [[NSFileManager defaultManager]fileExistsAtPath:theFile isDirectory:&isDirMe];
        
        ZipFile *zipFile = [[ZipFile alloc]initWithFileName:file mode:(fileSize(file) == 0)?ZipFileModeCreate:ZipFileModeAppend];

        if (!isDirMe) {
            
            ZipWriteStream *stream1 = [zipFile writeFileInZipWithName:[theFile lastPathComponent] fileDate:fileDate(file)/*[NSDate dateWithTimeIntervalSinceNow:-86400.0]*/ compressionLevel:ZipCompressionLevelBest];
            
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:theFile];
            
            do {
                int fsZ = fileSize(theFile);
                int readLength = 1024*1024;
                if (fsZ < readLength) {
                    readLength = fsZ;
                }
                NSData *readData = [fileHandle readDataOfLength:readLength];
                if (readData.length == 0) {
                    break;
                } else {
                    [stream1 writeData:readData];
                }
            } while (YES);
                
            [fileHandle closeFile];

            [stream1 finishedWriting];
        } else {
            
            NSString *origDir = [theFile lastPathComponent];
            NSString *dash = [origDir substringFromIndex:origDir.length-1];
            
            if (![dash isEqualToString:@"/"]) {
                origDir = [origDir stringByAppendingString:@"/"];
            }
            
            ZipWriteStream *stream1 = [zipFile writeFileInZipWithName:origDir fileDate:fileDate(theFile)/*[NSDate dateWithTimeIntervalSinceNow:-86400.0]*/ compressionLevel:ZipCompressionLevelBest];
            
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:theFile];
            
            do {
                NSData *readData = [fileHandle readDataOfLength:1024*1024];
                if (readData.length == 0) {
                    break;
                } else {
                    [stream1 writeData:readData];
                }
            } while (YES);
            
            [fileHandle closeFile];
            
            [stream1 finishedWriting];
            
                
            NSArray *array = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:theFile error:nil]; // a directory being added to a zip
                
            NSMutableArray *dirsInDir = [[NSMutableArray alloc]init];
                
            for (NSString *filename in array) {
                NSString *thing = [theFile stringByAppendingPathComponent:filename];
                    
                BOOL shouldBeADir;
                BOOL shouldBeADirOne = [[NSFileManager defaultManager]fileExistsAtPath:thing isDirectory:&shouldBeADir];
                    
                if (shouldBeADir && shouldBeADirOne) {
                    [dirsInDir addObject:thing];
                } else if (shouldBeADirOne) {
                    NSString *finalFN = [[theFile lastPathComponent]stringByAppendingPathComponent:filename];
                    ZipWriteStream *stream1 = [zipFile writeFileInZipWithName:finalFN fileDate:[NSDate dateWithTimeIntervalSinceNow:-86400.0] compressionLevel:ZipCompressionLevelBest];
                    
                    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:thing];
                    
                    do {
                        int fsZ = fileSize(thing);
                        int readLength = 1024*1024;
                        if (fsZ < readLength) {
                            readLength = fsZ;
                        }
                        NSData *readData = [fileHandle readDataOfLength:readLength];
                        if (readData.length == 0) {
                            break;
                        } else {
                            [stream1 writeData:readData];
                        }
                    } while (YES);
                    
                    [fileHandle closeFile];
                       
                    [stream1 finishedWriting];
                }
            }
            
            NSMutableArray *holdingArray = [[NSMutableArray alloc]init];
            
            do {
  
                for (NSString *dir in dirsInDir) {
                
                    NSString *dirRelative = [dir stringByReplacingOccurrencesOfString:[currentDir stringByAppendingString:@"/"]withString:@""]; // gets current directory in zip
                
                    NSString *asdfasdf = [dirRelative substringFromIndex:[dirRelative length]-1];

                    if (![asdfasdf isEqualToString:@"/"]) {
                        dirRelative = [dirRelative stringByAppendingString:@"/"];
                    }

                    ZipWriteStream *stream1 = [zipFile writeFileInZipWithName:dirRelative fileDate:fileDate(dir)/*[NSDate dateWithTimeIntervalSinceNow:-86400.0]*/ compressionLevel:ZipCompressionLevelBest];
                    [stream1 writeData:[NSData dataWithContentsOfFile:dir]]; // okay not to chunk
                    [stream1 finishedWriting];
                    
                    NSArray *arrayZ = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:dir error:nil];
                
                    for (NSString *stringy in arrayZ) {
                        
                        NSString *lolz = [dir stringByAppendingPathComponent:stringy]; // stringy used to be dir
                        
                        BOOL dirIsMe;
                        [[NSFileManager defaultManager]fileExistsAtPath:lolz isDirectory:&dirIsMe];
                        
                        if (dirIsMe) {
                            [holdingArray addObject:lolz];
                        } else {
                            NSString *nameOfFile = [dirRelative stringByAppendingPathComponent:stringy];
                            ZipWriteStream *stream1 = [zipFile writeFileInZipWithName:nameOfFile fileDate:/*[NSDate dateWithTimeIntervalSinceNow:-86400.0]*/fileDate(lolz) compressionLevel:ZipCompressionLevelBest];
                        
                            [[[NSFileManager defaultManager]attributesOfFileSystemForPath:lolz error:nil]fileCreationDate];
                            
                            NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:lolz];
                            
                            do {
                                NSData *readData = [fileHandle readDataOfLength:1024*1024];
                                if (readData.length == 0) {
                                    break;
                                } else {
                                    [stream1 writeData:readData];
                                }
                            } while (YES);
                        
                            [fileHandle closeFile];
                
                            [stream1 finishedWriting];
                        }
                    }
                }
            
                if (holdingArray.count == 0) {
                    break;
                } else {
                    [dirsInDir removeAllObjects];
                    [dirsInDir addObjectsFromArray:holdingArray];
                    /*for (NSString *string in holdingArray) {
                        [dirsInDir addObject:string];
                    }*/
                    [holdingArray removeAllObjects];
                }
                
            } while (YES);
        }
        
        [zipFile close];
        
        [self refreshTableViewWithAnimation:UITableViewRowAnimationNone];
        
        [[BGProcFactory sharedFactory]endProcForKey:@"compress"];
        
        [UIApplication sharedApplication].idleTimerDisabled = NO;
    }
}

- (void)showFileCreationDialogue {
    [[[FileCreationDialogue alloc]initWithCompletionBlock:^(FileCreationDialogueFileType fileType, NSString *fileName) {
        NSString *thingToBeCreated = getNonConflictingFilePathForPath([[kAppDelegate managerCurrentDir]stringByAppendingPathComponent:fileName]);
        if (fileType == FileCreationDialogueFileTypeFile) {
            [[NSFileManager defaultManager]createFileAtPath:thingToBeCreated contents:nil attributes:nil];
        } else if (fileType == FileCreationDialogueFileTypeDirectory) {
            [[NSFileManager defaultManager]createDirectoryAtPath:thingToBeCreated withIntermediateDirectories:NO attributes:nil error:nil];
        }
        [self refreshTableViewWithAnimation:UITableViewRowAnimationFade];
    }]show];
}

- (void)recalculateDirs {
    
    if (_dirs == nil) {
        self.dirs = [NSMutableArray array];
    } else {
        [_dirs removeAllObjects];
    }
    
    NSString *dirdisp = _navBar.topItem.title;
    
    NSArray *addPathComponents = [dirdisp pathComponents];
    int count = addPathComponents.count;

    NSString *previousPath = [kDocsDir stringByAppendingPathComponent:[dirdisp stringByDeletingLastPathComponent]];
    for (int i = 0; i < count; i++) {
        
        NSString *stringy = previousPath;
        for (int removalTimes = i-count+1; removalTimes < 0; removalTimes++) {
            stringy = [stringy stringByDeletingLastPathComponent];
        }
        [_dirs addObject:stringy];
    }
}

- (void)goBackDir {
    [self removeSideSwipeView:NO];

    [self recalculateDirs];

    NSString *prevDir = [_dirs lastObject];
    
    [kAppDelegate setManagerCurrentDir:prevDir];
    [self.dirs removeObject:[_dirs lastObject]];

    _navBar.topItem.title = [_navBar.topItem.title stringByDeletingLastPathComponent];

    [self refreshTableViewWithAnimation:UITableViewRowAnimationBottom];
}

- (void)showOptionsSheet:(id)sender {
    UIActionSheet *as = [[UIActionSheet alloc]initWithTitle:nil completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
        if (buttonIndex == 0) {
            [[[URLInputController alloc]initWithCompletionBlock:^(NSString *url) {
                [kAppDelegate downloadFile:url];
            }]show];
        } else if (buttonIndex == 1) {
            webDAVViewController *advc = [webDAVViewController viewController];
            [self presentModalViewController:advc animated:YES];
        } else if (buttonIndex == 2) {
            DropboxBrowserViewController *d = [DropboxBrowserViewController viewController];
            [self presentModalViewController:d animated:YES];
        } else if (buttonIndex == 3) {
            SFTPBrowserViewController *s = [SFTPBrowserViewController viewController];
            [self presentModalViewController:s animated:YES];
        } else if (buttonIndex == 4) {
            SettingsView *d = [SettingsView viewController];
            [self presentModalViewController:d animated:YES];
        }
    } cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Download URL", @"WebDAV Server", @"Browse Dropbox", @"Browse SFTP", @"Settings", nil];
    
    as.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    
    [as showFromBarButtonItem:sender animated:YES];
    
    [self removeSideSwipeView:NO];
}

- (BOOL)shouldTripWatchdog:(ContentOffsetWatchdog *)watchdog {
    return (![[kAppDelegate managerCurrentDir]isEqualToString:kDocsDir] && _watchdogCanGo && !_theTableView.isDecelerating);
}

- (void)watchdogWasTripped:(ContentOffsetWatchdog *)watchdog {
    if (!_theTableView.editing) {
        [watchdog resetOffset];
        [self goBackDir];
        [_filelist removeAllObjects];
        [_theTableView reloadDataWithCoolAnimationType:CoolRefreshAnimationStyleBackward];
        self.watchdogCanGo = NO;
    } else {
        [self showFileCreationDialogue];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    [self reindexFilelist];
    return _filelist.count;
}

- (void)accessoryButtonPressed:(id)sender {
    UIButton *button = (UIButton *)sender;
    CGPoint correctedPoint = [button convertPoint:button.bounds.origin toView:_theTableView];
    NSIndexPath *indexPath = [_theTableView indexPathForRowAtPoint:correctedPoint];
    
    NSString *fileName = [_theTableView cellForRowAtIndexPath:indexPath].textLabel.text;
    NSString *file = [[kAppDelegate managerCurrentDir] stringByAppendingPathComponent:fileName];
    
    [kAppDelegate setOpenFile:file];

    fileInfo *info = [fileInfo viewController];
    info.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentModalViewController:info animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    [self reindexFilelist];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[SwiftLoadCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];

        DisclosureButton *button = [DisclosureButton button];
        [button addTarget:self action:@selector(accessoryButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        cell.accessoryView = button;
        cell.accessoryView.backgroundColor = [UIColor whiteColor];
            
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            cell.accessoryView.center = CGPointMake(735, (cell.bounds.size.height)/2);
        } else {
            cell.accessoryView.center = CGPointMake(297.5, (cell.bounds.size.height)/2);
        }
        
        if (cell.gestureRecognizers.count == 0) {
            UISwipeGestureRecognizer *rightSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeRight:)];
            rightSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
            [cell addGestureRecognizer:rightSwipeGestureRecognizer];
            
            UISwipeGestureRecognizer *leftSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeLeft:)];
            leftSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
            [cell addGestureRecognizer:leftSwipeGestureRecognizer];
        }
    }
    
    NSString *filesObjectAtIndex = [_filelist objectAtIndex:indexPath.row];
    NSString *file = [[kAppDelegate managerCurrentDir]stringByAppendingPathComponent:filesObjectAtIndex];
    
    cell.textLabel.text = filesObjectAtIndex;
    
    BOOL isDir;
    
    if ([[NSFileManager defaultManager]fileExistsAtPath:file isDirectory:&isDir] && isDir) {
        cell.detailTextLabel.text = @"Directory";
        for (UIGestureRecognizer *rec in cell.gestureRecognizers) {
            rec.enabled = NO;
        }
    } else {
        for (UIGestureRecognizer *rec in cell.gestureRecognizers) {
            rec.enabled = YES;
        }
        NSString *detailText = [file.pathExtension.lowercaseString isEqualToString:@"zip"]?@"Archive, ":@"File, ";
        
        float fileSize = fileSize(file);
        
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
    }
    
    [cell setNeedsDisplay];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    AppDelegate *ad = kAppDelegate;
    UITableViewCell *cell = [_theTableView cellForRowAtIndexPath:indexPath];

    NSString *file = [ad.managerCurrentDir stringByAppendingPathComponent:cell.textLabel.text];
    ad.openFile = file;

    BOOL isDir;
    
    if ([[NSFileManager defaultManager]fileExistsAtPath:file isDirectory:&isDir] && isDir) {
        
        _navBar.topItem.title = [_navBar.topItem.title stringByAppendingPathComponent:file.lastPathComponent];
        
        [ad setManagerCurrentDir:file];
        
        [self recalculateDirs];
        
        [_filelist removeAllObjects];
        [_theTableView reloadDataWithCoolAnimationType:CoolRefreshAnimationStyleForward];
        [_theTableView flashScrollIndicators];
        
    } else if ([[[file pathExtension]lowercaseString]isEqualToString:@"zip"]) {
        
        UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:[NSString stringWithFormat:@"What would you like to do with %@",cell.textLabel.text] completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
            
            NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
            
            if ([title isEqualToString:@"Compress Copied Items"]) {
                if (_copiedList.count > 0) {
                    
                    [ad showHUDWithTitle:@"Compressing..."];
                    [ad setVisibleHudMode:MBProgressHUDModeIndeterminate];
                    [ad setTagOfVisibleHUD:4];
                    
                    [self compressItems:_copiedList intoZipFile:[ad.managerCurrentDir stringByAppendingPathComponent:[[actionSheet.title componentsSeparatedByString:@" "]lastObject]]];
                }
            } else if ([title isEqualToString:@"Decompress"]) {
                if (fileSize(file) > 0) {
                    [ad showHUDWithTitle:@"Inflating..."];
                    [ad setSecondaryTitleOfVisibleHUD:[file lastPathComponent]];
                    [ad setVisibleHudMode:MBProgressHUDModeDeterminate];
                    [ad setTagOfVisibleHUD:5];
                    [NSThread detachNewThreadSelector:@selector(inflate:) toTarget:self withObject:file];
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
        BOOL isHTML = [MIMEUtils isHTMLFile:file];
        
        if ([MIMEUtils isAudioFile:file]) {
            AudioPlayerViewController *audio = [AudioPlayerViewController viewController];
            audio.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
            [self presentModalViewController:audio animated:YES];
        } else if ([MIMEUtils isImageFile:file]) {
            pictureView *pView = [pictureView viewController];
            pView.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
            [self presentModalViewController:pView animated:YES];
        } else if ([MIMEUtils isTextFile:file] && !isHTML) {
            TextEditorViewController *textEditor = [TextEditorViewController viewController];
            textEditor.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
            [self presentModalViewController:textEditor animated:YES];
        } else if ([MIMEUtils isVideoFile:file]) {
            moviePlayerView *mpv = [moviePlayerView viewController];
            mpv.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
            [self presentModalViewController:mpv animated:YES];
        } else if ([MIMEUtils isDocumentFile:file] || isHTML) {
            MyFilesViewDetailViewController *detail = [MyFilesViewDetailViewController viewController];
            detail.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
            [self presentModalViewController:detail animated:YES];
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
    
    [self removeSideSwipeView:NO];
    
    if (_theTableView.editing) {
        [_theTableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
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
        [self reindexFilelist];
        NSString *file = [[kAppDelegate managerCurrentDir]stringByAppendingPathComponent:[_filelist objectAtIndex:indexPath.row]];
        BOOL isDir;
        return ([[NSFileManager defaultManager]fileExistsAtPath:file isDirectory:&isDir] && isDir);
    }
}

- (void)editTable {
    [self removeSideSwipeView:NO];
    [self reindexFilelist];
    
    _theTableView.allowsMultipleSelectionDuringEditing = !_theTableView.editing;
    _editButton.title = _theTableView.editing?@"Edit":@"Done";
    [_theTableView setEditing:!_theTableView.editing animated:YES];
    
    [self updateCopyButtonState];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (!indexPath) {
        return UITableViewCellEditingStyleNone;
    }
    
    if (_theTableView.editing) {
        return UITableViewCellEditingStyleNone;
    } else {
        [self reindexFilelist];
        
        NSString *file = [[kAppDelegate managerCurrentDir]stringByAppendingPathComponent:[_filelist objectAtIndex:indexPath.row]];
        
        BOOL isDir;
        [[NSFileManager defaultManager]fileExistsAtPath:file isDirectory:&isDir];
        
        if (isDir) {
            [self removeSideSwipeView:YES];
            return UITableViewCellEditingStyleDelete;
        }
        return UITableViewCellEditingStyleNone;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *cellName = [_theTableView cellForRowAtIndexPath:indexPath].textLabel.text;
        NSString *removePath = [[kAppDelegate managerCurrentDir]stringByAppendingPathComponent:cellName];
        
        [_theTableView beginUpdates];
        [_theTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
        NSFileManager *fm = [[NSFileManager alloc]init];
        [fm removeItemAtPath:removePath error:nil];
        [_filelist removeAllObjects];
        [_theTableView endUpdates];
    }
}

- (void)actionSheetAction:(UIActionSheet *)actionSheet buttonIndex:(int)buttonIndex {
    
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }
    
    if (buttonIndex == 0) {
        TextEditorViewController *textEditor = [TextEditorViewController viewController];
        textEditor.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [self presentModalViewController:textEditor animated:YES];
    } else if (buttonIndex == 1) {
        moviePlayerView *textEditor = [moviePlayerView viewController];
        textEditor.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [self presentModalViewController:textEditor animated:YES];
    } else if (buttonIndex == 2) {
        pictureView *textEditor = [pictureView viewController];
        textEditor.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [self presentModalViewController:textEditor animated:YES];
    } else if (buttonIndex == 3) {
        AudioPlayerViewController *textEditor = [AudioPlayerViewController viewController];
        textEditor.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [self presentModalViewController:textEditor animated:YES];
    } else if (buttonIndex == 4) {
        MyFilesViewDetailViewController *textEditor = [MyFilesViewDetailViewController viewController];
        textEditor.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [self presentModalViewController:textEditor animated:YES];
    } else if (buttonIndex == 5) {
        NSString *file = [kAppDelegate openFile];
        UIDocumentInteractionController *controller = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:file]];
        
        BOOL opened = NO;
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            opened = [controller presentOpenInMenuFromRect:_sideSwipeCell.frame inView:_theTableView animated:YES];
        } else {
            opened = [controller presentOpenInMenuFromRect:self.view.frame inView:self.view animated:YES];
        }
        
        if (!opened) {
            [TransparentAlert showAlertWithTitle:@"No External Viewers" andMessage:[NSString stringWithFormat:@"No installed applications are capable of opening %@.",[file lastPathComponent]]];
        }
    }
    [self removeSideSwipeView:YES];
}

- (void)touchUpInsideAction:(UIButton *)button {
    NSString *file = [[kAppDelegate managerCurrentDir]stringByAppendingPathComponent:_sideSwipeCell.textLabel.text];
    [kAppDelegate setOpenFile:file];
    
    int number = button.tag-1;
    
    if (number == 0) {
        NSString *message = [NSString stringWithFormat:@"What would you like to do with %@?",file.lastPathComponent];
        
        UIActionSheet *popupQuery = [[UIActionSheet alloc]initWithTitle:message completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
            [self actionSheetAction:actionSheet buttonIndex:buttonIndex];
        } cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Open In Text Editor", @"Open In Movie Player", @"Open In Picture Viewer", @"Open In Audio Player", @"Open In Document Viewer", @"Open In...", nil];
        popupQuery.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            [popupQuery showFromRect:[self.sideSwipeView convertRect:button.frame toView:self.view] inView:self.view animated:YES];
        } else {
            [popupQuery showInView:self.view];
            [self removeSideSwipeView:YES];
        }
        
    } else if (number == 1) {
        [kAppDelegate uploadLocalFile:file];
        [self removeSideSwipeView:YES];
    } else if (number == 2) {
        [kAppDelegate prepareFileForBTSending:file];
        //[kAppDelegate showBTController];
        [self removeSideSwipeView:YES];
    } else if (number == 3) {
        [kAppDelegate sendFileInEmail:file fromViewController:self];
        [self removeSideSwipeView:YES];
        
    } else if (number == 4) {
        NSString *message = [NSString stringWithFormat:@"Are you sure you want to delete %@?",[file lastPathComponent]];
        
        UIActionSheet *popupQuery = [[UIActionSheet alloc]initWithTitle:message completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
            
            if (buttonIndex == actionSheet.destructiveButtonIndex) {
                
                [kAppDelegate showHUDWithTitle:@"Deleting"];
                [kAppDelegate setTitleOfVisibleHUD:file.lastPathComponent];
                [kAppDelegate setVisibleHudMode:MBProgressHUDModeIndeterminate];
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    @autoreleasepool {
                        NSFileManager *fm = [[NSFileManager alloc]init];
                        [fm removeItemAtPath:file error:nil];
                        
                        [_filelist removeAllObjects];
                        
                        NSIndexPath *indexPath = [_theTableView indexPathForCell:_sideSwipeCell];
                        
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            @autoreleasepool {
                                [kAppDelegate hideHUD];
                                [self removeSideSwipeView:NO];
                                [_theTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
                            }
                        });
                    
                    }
                });

                
            }
            
        } cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"I'm sure, Delete" otherButtonTitles:nil];
        popupQuery.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        [popupQuery showInView:self.view];
    }
}

- (void)setupSideSwipeView {
 
    if (_sideSwipeView == nil) {
        self.sideSwipeView = [[UIView alloc]initWithFrame:CGRectMake(_theTableView.frame.origin.x, _theTableView.frame.origin.y, _theTableView.frame.size.width, _theTableView.rowHeight)];
        _sideSwipeView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        _sideSwipeView.backgroundColor = [UIColor darkGrayColor];
        
        UIImageView *shadowImageView = [[UIImageView alloc]initWithFrame:_sideSwipeView.bounds];
        shadowImageView.alpha = 0.7;
        shadowImageView.image = [[UIImage imageNamed:@"inner-shadow"]stretchableImageWithLeftCapWidth:10 topCapHeight:10];
        shadowImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [_sideSwipeView addSubview:shadowImageView];
        
        UISwipeGestureRecognizer *rightSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeRight:)];
        rightSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
        [_sideSwipeView addGestureRecognizer:rightSwipeGestureRecognizer];

        UISwipeGestureRecognizer *leftSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeLeft:)];
        leftSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
        [_sideSwipeView addGestureRecognizer:leftSwipeGestureRecognizer];
    } else {
        for (UIView *view in _sideSwipeView.subviews) {
            if ([view isKindOfClass:[UIButton class]]) {
                [view removeFromSuperview];
            }
        }
    }
    
    NSMutableArray *buttonData = [NSMutableArray arrayWithObjects:@{@"title": @"Action", @"image": @"action"}, @{@"title": @"FTP", @"image": @"dropbox"}, @{@"title": @"Bluetooth", @"image": @"bluetooth"}, @{@"title": @"Email", @"image": @"paperclip"}, @{@"title": @"Delete", @"image": @"delete"}, nil];
    
    NSString *filePath = [[kAppDelegate managerCurrentDir]stringByAppendingPathComponent:_sideSwipeCell.textLabel.text];
    
    if ([filePath isEqualToString:[kAppDelegate nowPlayingFile]]) {
        [buttonData removeObject:buttonData.lastObject];
    }
    
    for (NSDictionary *buttonInfo in buttonData) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake([buttonData indexOfObject:buttonInfo]*((_sideSwipeView.bounds.size.width)/buttonData.count), 0, ((_sideSwipeView.bounds.size.width)/buttonData.count), _sideSwipeView.bounds.size.height);
        button.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
        
        UIImage *grayImage = [[UIImage imageNamed:[buttonInfo objectForKey:@"image"]]imageFilledWith:[UIColor colorWithWhite:0.9 alpha:1.0]];
        [button setImage:grayImage forState:UIControlStateNormal];
        [button setTag:[buttonData indexOfObject:buttonInfo]+1];
        [button addTarget:self action:@selector(touchUpInsideAction:) forControlEvents:UIControlEventTouchUpInside];
        [_sideSwipeView addSubview:button];
    }
}

- (void)swipeLeft:(UISwipeGestureRecognizer *)recognizer {
    [self swipe:recognizer direction:UISwipeGestureRecognizerDirectionLeft];
}

- (void)swipeRight:(UISwipeGestureRecognizer *)recognizer {
    [self swipe:recognizer direction:UISwipeGestureRecognizerDirectionRight];
}

- (void)swipe:(UISwipeGestureRecognizer *)recognizer direction:(UISwipeGestureRecognizerDirection)direction {

    if (_theTableView.editing) {
        return;
    }
    
    if (recognizer && recognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint location = [recognizer locationInView:_theTableView];
        NSIndexPath *indexPath = [_theTableView indexPathForRowAtPoint:location];
        UITableViewCell *cell = [_theTableView cellForRowAtIndexPath:indexPath];
        
        if (cell.frame.origin.x != 0) {
            [self removeSideSwipeView:YES];
            return;
        }
        
        [self removeSideSwipeView:NO];
        
        if (cell != _sideSwipeCell && !_animatingSideSwipe) {
            [self setupSideSwipeView];
            [self addSwipeViewTo:cell direction:recognizer.direction];
        }
    }
}

- (void)addSwipeViewTo:(UITableViewCell *)cell direction:(UISwipeGestureRecognizerDirection)direction {
    CGRect cellFrame = cell.frame;
    
    [self setSideSwipeCell:cell];
    _sideSwipeView.frame = CGRectMake(0, cellFrame.origin.y, cellFrame.size.width, cellFrame.size.height);
    [_theTableView insertSubview:_sideSwipeView belowSubview:cell];
    self.sideSwipeDirection = direction;
    
    self.animatingSideSwipe = YES;
    
    [UIView animateWithDuration:0.2 animations:^{
        cell.frame = CGRectMake(direction == UISwipeGestureRecognizerDirectionRight?cellFrame.size.width:-cellFrame.size.width, cellFrame.origin.y, cellFrame.size.width, cellFrame.size.height);
    } completion:^(BOOL finished) {
        self.animatingSideSwipe = NO;
    }];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self removeSideSwipeView:YES];
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    [self removeSideSwipeView:NO];
    return YES;
}

- (void)removeSideSwipeView:(BOOL)animated {
    
    if (_animatingSideSwipe) {
        return;
    }
    
    if (!_sideSwipeCell) {
        return;
    }
    
    if (!_sideSwipeView) {
        return;
    }
    
    if (animated) {
        
        [UIView animateWithDuration:0.2 animations:^{
            float bouncepixels = (_sideSwipeDirection == UISwipeGestureRecognizerDirectionRight)?BOUNCE_PIXELS:-BOUNCE_PIXELS;
            _sideSwipeCell.frame = CGRectMake(bouncepixels, _sideSwipeCell.frame.origin.y, _sideSwipeCell.frame.size.width, _sideSwipeCell.frame.size.height);
            self.animatingSideSwipe = YES;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.2 animations:^{
                float bouncepixels = ((_sideSwipeDirection == UISwipeGestureRecognizerDirectionRight)?BOUNCE_PIXELS:-BOUNCE_PIXELS)*2;
                _sideSwipeCell.frame = CGRectMake(bouncepixels, _sideSwipeCell.frame.origin.y, _sideSwipeCell.frame.size.width, _sideSwipeCell.frame.size.height);
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.2 animations:^{
                    _sideSwipeCell.frame = CGRectMake(0, _sideSwipeCell.frame.origin.y, _sideSwipeCell.frame.size.width, _sideSwipeCell.frame.size.height);
                } completion:^(BOOL finished) {
                    [UIView animateWithDuration:0.2 animations:^{
                        self.animatingSideSwipe = NO;
                        [self removeSideSwipeView:NO];
                    } completion:nil];
                }];
            }];
        }];
    } else {
        self.animatingSideSwipe = NO;
        
        if (_sideSwipeView.superview != nil) {
            [_sideSwipeView removeFromSuperview];
        }
        
        [self setSideSwipeView:nil];
        
        if (_sideSwipeCell != nil) {
            _sideSwipeCell.frame = CGRectMake(0, _sideSwipeCell.frame.origin.y, _sideSwipeCell.frame.size.width, _sideSwipeCell.frame.size.height);
            [self setSideSwipeCell:nil];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [_filelist removeAllObjects];
    [_theTableView reloadData];
    [self.theTableView flashScrollIndicators];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self removeSideSwipeView:NO];
    [self setupSideSwipeView];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end
