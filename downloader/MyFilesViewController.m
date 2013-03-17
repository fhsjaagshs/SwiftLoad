//
//  MyFilesViewController.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 8/11/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//


#import "MyFilesViewController.h"
#import "ButtonBarView.h"
#import "CustomCellCell.h"

#define BOUNCE_PIXELS 5.0

@implementation MyFilesViewController

@synthesize dirs, sideSwipeDirection, sideSwipeCell, sideSwipeView, animatingSideSwipe, editButton, theTableView, backButton, homeButton, filelist, docController, isCut, copiedList, perspectiveCopiedList, theCopyAndPasteButton;

- (void)loadView {
    [super loadView];
    
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    
    self.view = [[[UIView alloc]initWithFrame:screenBounds]autorelease];
    self.view.backgroundColor = [UIColor clearColor];
    
    self.navBar = [[[CustomNavBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)]autorelease];
    self.navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[[UINavigationItem alloc]initWithTitle:@"/"]autorelease];
    // Will give you a nifty down-pointing arrow
    // self.editButton = [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:@"Edit" target:self action:@selector(editTable)]autorelease];
    self.editButton = [[[UIBarButtonItem alloc]initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered target:self action:@selector(editTable)]autorelease];
    topItem.rightBarButtonItem = self.editButton;
    topItem.leftBarButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)]autorelease];
    [self.navBar pushNavigationItem:topItem animated:YES];
    [self.view addSubview:self.navBar];
    [self.view bringSubviewToFront:self.navBar];
    
    ButtonBarView *bbv = [[[ButtonBarView alloc]initWithFrame:CGRectMake(0, 44, screenBounds.size.width, 44)]autorelease];
    bbv.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:bbv];
    
    self.theCopyAndPasteButton = [[[CustomButton alloc]initWithFrame:iPad?CGRectMake(612, 4, 36, 36):CGRectMake(232, 5, 36, 36)]autorelease];
    self.theCopyAndPasteButton.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    UIImage *grayImage = [self imageFilledWith:[UIColor colorWithWhite:1.0f alpha:1.0f] using:[UIImage imageNamed:@"clipboard"]];
    [self.theCopyAndPasteButton setImage:grayImage forState:UIControlStateNormal];
    [self.theCopyAndPasteButton addTarget:self action:@selector(showCopyPasteController) forControlEvents:UIControlEventTouchUpInside];
    [bbv addSubview:self.theCopyAndPasteButton];
    [self.theCopyAndPasteButton setHidden:YES];
    
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
    
    PullToRefreshView *pull = [[PullToRefreshView alloc]initWithScrollView:self.theTableView];
    [pull setDelegate:self];
    [self.theTableView addSubview:pull];
    [pull release];
    
    [kAppDelegate setManagerCurrentDir:kDocsDir];
    
    self.animatingSideSwipe = NO;
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(copiedListChanged:) name:@"copiedlistchanged" object:nil];
}

- (void)removeAllCheckmarks {
    for (int i = 0; i < self.filelist.count; i++) {
        UITableViewCell *cell = [self.theTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        cell.editingAccessoryType = UITableViewCellEditingStyleNone;
    }
}

- (void)pasteInLocation:(NSString *)location {
    for (NSString *oldPath in self.copiedList) {
        NSString *newPath = getNonConflictingFilePathForPath([location stringByAppendingPathComponent:[oldPath lastPathComponent]]);
        
        NSError *error = nil;
        
        if (self.isCut) {
            [[NSFileManager defaultManager]moveItemAtPath:oldPath toPath:newPath error:&error];
        } else {
            [[NSFileManager defaultManager]copyItemAtPath:oldPath toPath:newPath error:&error];
        }
    }
    [self flushCopiedList];
    [self refreshTableViewWithAnimation:UITableViewRowAnimationFade];
    [self updateCopyButtonState];
}

- (void)copyFilesWithIsCut:(BOOL)cut {
    self.isCut = cut;
    [self saveIsCutBOOL];
    [self verifyProspectiveCopyList];
    [self flushCopiedList];
    [self.copiedList addObjectsFromArray:self.perspectiveCopiedList];
    [self flushPerspectiveCopyList];
    [self saveCopiedList];
    [self updateCopyButtonState];
    [self removeAllCheckmarks];
}

// BOOL value of YES is success adding to the array
- (BOOL)addItemToPerspectiveCopyList:(NSString *)item {
    [self verifyProspectiveCopyList];
    [self verifyCopiedList];
    
    if (self.copiedList.count > 0) {
        return NO;
    }
    
    if (![self.perspectiveCopiedList containsObject:item]) {
        [self.perspectiveCopiedList addObject:item];
        return YES;
    }
    
    return NO;
}

- (void)removeItemFromPerspectiveCopyList:(NSString *)item {
    [self verifyProspectiveCopyList];
    if ([self.perspectiveCopiedList containsObject:item]) {
        [self.perspectiveCopiedList removeObject:item];
    }
}

- (void)saveIsCutBOOL {
    [[NSUserDefaults standardUserDefaults]setBool:self.isCut forKey:@"isCutBool"];
}

- (void)verifyIsCutBOOL {
    self.isCut = [[NSUserDefaults standardUserDefaults]boolForKey:@"isCutBool"];
}

- (void)saveProspectiveCopyList {
    [[NSUserDefaults standardUserDefaults]setObject:self.perspectiveCopiedList forKey:@"saved_copy_list_pers"];
}

- (void)flushPerspectiveCopyList {
    [self.perspectiveCopiedList removeAllObjects];
    [self saveProspectiveCopyList];
}

- (void)verifyProspectiveCopyList {
    if (self.perspectiveCopiedList.count == 0) {
        self.perspectiveCopiedList = [NSMutableArray array];
    }
    
    NSArray *listFromDefaults = [[NSUserDefaults standardUserDefaults]objectForKey:@"saved_copy_list_pers"];
    
    for (id obj in listFromDefaults) {
        if (![self.perspectiveCopiedList containsObject:obj]) {
            [self.perspectiveCopiedList addObject:obj];
        }
    }
}

- (void)flushCopiedList {
    [self.copiedList removeAllObjects];
    [self saveCopiedList];
}

- (void)saveCopiedList {
    [[NSUserDefaults standardUserDefaults]setObject:self.copiedList forKey:@"saved_copied_list"];
}

- (void)verifyCopiedList {
    if (self.copiedList.count == 0) {
        self.copiedList = [NSMutableArray array];
    }
    
    NSArray *listFromDefaults = [[NSUserDefaults standardUserDefaults]objectForKey:@"saved_copied_list"];
    
    for (id obj in listFromDefaults) {
        if (![self.copiedList containsObject:obj]) {
            [self.copiedList addObject:obj];
        }
    }
}

- (void)copiedListChanged:(NSNotification *)notif {
    
    [self verifyCopiedList];
    [self verifyProspectiveCopyList];
    
    NSMutableDictionary *changedDict = [[(NSDictionary *)[notif object]mutableCopy]autorelease];
    
    NSString *old = [changedDict objectForKey:@"old"];
    NSString *new = [changedDict objectForKey:@"new"];
    
    if ([self.copiedList containsObject:old]) {
        [self.copiedList replaceObjectAtIndex:[self.copiedList indexOfObject:old] withObject:new];
    }
    
    if ([self.perspectiveCopiedList containsObject:old]) {
        [self.perspectiveCopiedList replaceObjectAtIndex:[self.perspectiveCopiedList indexOfObject:old] withObject:new];
    }
    
    [self saveCopiedList];
    [self saveProspectiveCopyList];
}

- (void)showCopyPasteController {
    UIActionSheet *actionSheet = [[[UIActionSheet alloc]initWithTitle:nil completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
        
        NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
        
        if ([title isEqualToString:@"Copy"]) {
            [self copyFilesWithIsCut:NO];
        } else if ([title isEqualToString:@"Cut"]) {
            [self copyFilesWithIsCut:YES];
        } else if ([title isEqualToString:@"Paste"]) {
            [self pasteInLocation:[kAppDelegate managerCurrentDir]];
        } else if ([title isEqualToString:@"Cancel"]) {
            [self verifyCopiedList];
            if (self.copiedList.count > 0) {
                [self flushCopiedList];
                [self flushPerspectiveCopyList];
            }
        }
        [self updateCopyButtonState];
    } cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil]autorelease];
    
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    
    [self verifyCopiedList];
    
    if (self.copiedList.count == 0) {
        [actionSheet addButtonWithTitle:@"Copy"];
        [actionSheet addButtonWithTitle:@"Cut"];
    } else {
        [actionSheet addButtonWithTitle:@"Paste"];
    }
    
    [actionSheet addButtonWithTitle:@"Cancel"];
    
    actionSheet.cancelButtonIndex = actionSheet.numberOfButtons-1;
    
    [actionSheet showInView:self.view];
}

- (void)updateCopyButtonState {
    
    if (!self.editing) {
        [self.theCopyAndPasteButton setHidden:YES];
        return;
    }
    
    [self verifyProspectiveCopyList];
    [self verifyCopiedList];
    
    BOOL persCLGT = (self.perspectiveCopiedList.count > 0);
    BOOL CLGT = (self.copiedList.count > 0);
    BOOL shouldUnhide = ((persCLGT || CLGT) || (persCLGT && CLGT));
    
    [self.theCopyAndPasteButton setHidden:!shouldUnhide];
}

- (void)reindexFilelist {
    if (self.filelist == nil) {
        [self setFilelist:[NSMutableArray array]];
    }
    
    if (self.filelist.count == 0) {
        [self.filelist addObjectsFromArray:[[[NSFileManager defaultManager]contentsOfDirectoryAtPath:[kAppDelegate managerCurrentDir] error:nil]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
    }
}

- (void)refreshTableViewWithAnimation:(UITableViewRowAnimation)rowAnim {
    [self.filelist removeAllObjects];
    [self.theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:rowAnim];
}

- (void)inflate:(NSString *)file {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
    
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
                [buffer release];
            } else {
                unachivedBytes = unachivedBytes+info.length;
                HUDZ.progress = (unachivedBytes/filesize);
            }
        }
    }
    [unzipFile close];
    [unzipFile release];
    
    [kAppDelegate hideHUD];
    
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [self refreshTableViewWithAnimation:UITableViewRowAnimationNone];
    
    [pool release];
}

- (void)compressItems:(NSArray *)items intoZipFile:(NSString *)file {
    for (NSString *theFile in items) {
        [kAppDelegate setSecondaryTitleOfVisibleHUD:[theFile lastPathComponent]];
        [self compressItem:theFile intoZipFile:file];
    }
    [kAppDelegate hideHUD];
}

- (void)compressItem:(NSString *)theFile intoZipFile:(NSString *)file {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    NSString *currentDir = [kAppDelegate managerCurrentDir];
    
    BOOL isDirMe;    
    [[NSFileManager defaultManager]fileExistsAtPath:theFile isDirectory:&isDirMe];
    
    ZipFile *zipFile = nil;
    
    if (fileSize(file) == 0) {
        zipFile = [[ZipFile alloc]initWithFileName:file mode:ZipFileModeCreate];
    } else {
        zipFile = [[ZipFile alloc]initWithFileName:file mode:ZipFileModeAppend];
    }

    if (!isDirMe) {
        
        ZipWriteStream *stream1 = [zipFile writeFileInZipWithName:[theFile lastPathComponent] fileDate:[NSDate dateWithTimeIntervalSinceNow:-86400.0] compressionLevel:ZipCompressionLevelBest];
        
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
        NSString *dash = [origDir substringFromIndex:[origDir length]-1];
            
        BOOL hasSlash = [dash isEqualToString:@"/"];
            
        if (!hasSlash) {
            origDir = [origDir stringByAppendingString:@"/"];
        }
        
        ZipWriteStream *stream1 = [zipFile writeFileInZipWithName:origDir fileDate:[NSDate dateWithTimeIntervalSinceNow:-86400.0] compressionLevel:ZipCompressionLevelBest];
        
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
            
                BOOL DRHasSlashAtEnd = [asdfasdf isEqualToString:@"/"];
            
                if (!DRHasSlashAtEnd) {
                    dirRelative = [dirRelative stringByAppendingString:@"/"];
                }

                ZipWriteStream *stream1 = [zipFile writeFileInZipWithName:dirRelative fileDate:[NSDate dateWithTimeIntervalSinceNow:-86400.0] compressionLevel:ZipCompressionLevelBest];
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
                        ZipWriteStream *stream1 = [zipFile writeFileInZipWithName:nameOfFile fileDate:[NSDate dateWithTimeIntervalSinceNow:-86400.0] compressionLevel:ZipCompressionLevelBest]; 
                    
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
            for (NSString *string in holdingArray) {
                [dirsInDir addObject:string];
            }
            [holdingArray removeAllObjects];
        }
            
        } while (YES);
        [holdingArray release];
        [dirsInDir release];
    }
    
    [zipFile close];
    [zipFile release];
    
    int totalIndex = [self.theTableView numberOfSections]-1;
    
    for (int i = 0; i <= totalIndex; i++) {
        [[self.theTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]]setEditingAccessoryType:UITableViewCellAccessoryNone];
    }
    
    [self refreshTableViewWithAnimation:UITableViewRowAnimationNone];

    [UIApplication sharedApplication].idleTimerDisabled = NO;
    
    [pool release];
}

- (void)showFileCreationAlertView {
    av = [[CustomAlertView alloc]initWithTitle:@"Create File or Directory" message:@"\n\n\n\n" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
    
    CustomButton *createFile = [[CustomButton alloc]initWithFrame:CGRectMake(12, 90, 126, 37)];
    [createFile setTitle:@"File" forState:UIControlStateNormal];
    [createFile addTarget:self action:@selector(createTheFile) forControlEvents:UIControlEventTouchUpInside];
    [createFile setTitleColor:[UIColor whiteColor]forState:UIControlStateNormal];
    createFile.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [createFile setTitleShadowColor:[UIColor blackColor] forState:UIControlStateNormal];
    [createFile setBackgroundColor:[UIColor clearColor]];
    createFile.titleLabel.shadowOffset = CGSizeMake(0, -1);

    CustomButton *createDir = [[CustomButton alloc]initWithFrame:CGRectMake(145, 90, 126, 37)];
    [createDir setTitle:@"Directory" forState:UIControlStateNormal];
    [createDir addTarget:self action:@selector(createTheDir) forControlEvents:UIControlEventTouchUpInside];
    [createDir setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    createDir.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [createDir setTitleShadowColor:[UIColor blackColor] forState:UIControlStateNormal];
    [createDir setBackgroundColor:[UIColor clearColor]];
    createDir.titleLabel.shadowOffset = CGSizeMake(0, -1);
    
    tv = [[CustomTextField alloc]initWithFrame:CGRectMake(43, 48, 200, 31)];
    [tv becomeFirstResponder];
    [tv setKeyboardAppearance:UIKeyboardAppearanceAlert];
    [tv setBorderStyle:UITextBorderStyleBezel];
    [tv setBackgroundColor:[UIColor clearColor]];
    [tv setReturnKeyType:UIReturnKeyDone];
    [tv setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [tv setAutocorrectionType:UITextAutocorrectionTypeNo];
    [tv setPlaceholder:@"File/Directory Name"];
    [tv setFont:[UIFont boldSystemFontOfSize:18]];
    [tv setAdjustsFontSizeToFitWidth:YES];
    tv.clearButtonMode = UITextFieldViewModeWhileEditing;
    [tv addTarget:self action:@selector(hideFileCreationKB) forControlEvents:UIControlEventEditingDidEndOnExit];
    
    [av addSubview:createFile];
    [av addSubview:createDir];
    [av addSubview:tv];
    [av show];
    [av release];
    [tv release];
    [createFile release];
    [createDir release];
}

- (void)hideFileCreationKB {
    [tv resignFirstResponder];
}

- (void)recalculateDirs {
    
    if (self.dirs == nil) {
        self.dirs = [NSMutableArray array];
    }
    
    [self.dirs removeAllObjects];
    
    NSString *dirdisp = self.navBar.topItem.title;
    
    NSArray *addPathComponents = [dirdisp pathComponents];
    int count = addPathComponents.count;

    NSString *previousPath = [kDocsDir stringByAppendingPathComponent:[dirdisp stringByDeletingLastPathComponent]];
    for (int i = 0; i < count; i++) {
        
        NSString *stringy = previousPath;
        for (int removalTimes = i-count+1; removalTimes < 0; removalTimes++) {
            stringy = [stringy stringByDeletingLastPathComponent];
        }
        [self.dirs addObject:stringy];
    }
}

- (void)goBackDir {
    [self removeSideSwipeView:NO];

    [self recalculateDirs];

    NSString *prevDir = [self.dirs lastObject];
    
    [kAppDelegate setManagerCurrentDir:prevDir];
    [self.dirs removeObject:[self.dirs lastObject]];

    self.navBar.topItem.title = [self.navBar.topItem.title stringByDeletingLastPathComponent];

    if ([prevDir isEqualToString:kDocsDir]) {
        [self.backButton setHidden:YES];
        [self.homeButton setHidden:YES];
    }

    [self refreshTableViewWithAnimation:UITableViewRowAnimationRight];
}

- (void)goHome {
    [self removeSideSwipeView:NO];
    
    [self.dirs removeAllObjects];
    self.navBar.topItem.title = @"/";
    [self.backButton setHidden:YES];
    
    [kAppDelegate setManagerCurrentDir:kDocsDir];

    [self.homeButton setHidden:YES];
    
    [self refreshTableViewWithAnimation:UITableViewRowAnimationRight];
    [self.theTableView setContentOffset:CGPointMake(0, 0)];
}

- (void)close {
    [self removeSideSwipeView:NO];
    [self.dirs removeAllObjects];
    [self.filelist removeAllObjects];
    
    [self dismissModalViewControllerAnimated:YES];
}

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
        [NSThread sleepForTimeInterval:0.5f];
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSAutoreleasePool *poolTwo = [[NSAutoreleasePool alloc]init];
            [view finishedLoading];
            [self refreshTableViewWithAnimation:UITableViewRowAnimationFade];
            [poolTwo release];
        });
        [pool release];
    });
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    [self reindexFilelist];
    return self.editing?self.filelist.count+1:self.filelist.count;
}

- (void)accessoryButtonPressed:(id)sender {
    UIButton *button = (UIButton *)sender;
    CGPoint correctedPoint = [button convertPoint:button.bounds.origin toView:self.theTableView];
    NSIndexPath *indexPath = [self.theTableView indexPathForRowAtPoint:correctedPoint];
    
    NSString *fileName = [self.theTableView cellForRowAtIndexPath:indexPath].textLabel.text;
    NSString *file = [[kAppDelegate managerCurrentDir] stringByAppendingPathComponent:fileName];
    
    [kAppDelegate setOpenFile:file];

    fileInfo *info = [fileInfo viewController];
    info.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentModalViewController:info animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    [self reindexFilelist];
    
    static NSString *CellIdentifier = @"Cell";
    
    CustomCellCell *cell = (CustomCellCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[[CustomCellCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier]autorelease];
        
        DTCustomColoredAccessory *accessory = [DTCustomColoredAccessory accessoryWithColor:[UIColor whiteColor]];
        accessory.highlightedColor = [UIColor darkGrayColor];
        [accessory addTarget:self action:@selector(accessoryButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        cell.accessoryView = accessory;
            
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            cell.accessoryView.center = CGPointMake(735, (cell.bounds.size.height)/2);
            cell.textLabel.font = [UIFont fontWithName:@"MarkerFelt-Thin" size:27];
            cell.detailTextLabel.font = [UIFont systemFontOfSize:20.0];
        } else {
            cell.accessoryView.center = CGPointMake(297.5, (cell.bounds.size.height)/2);
            cell.textLabel.font = [UIFont fontWithName:@"MarkerFelt-Thin" size:20];
        }
        
        if (cell.gestureRecognizers.count == 0) {
            UISwipeGestureRecognizer *rightSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeRight:)];
            rightSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
            [cell addGestureRecognizer:rightSwipeGestureRecognizer];
            [rightSwipeGestureRecognizer release];
            
            UISwipeGestureRecognizer *leftSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeLeft:)];
            leftSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
            [cell addGestureRecognizer:leftSwipeGestureRecognizer];
            [leftSwipeGestureRecognizer release];
        }
    }

    if (self.editing && indexPath.row == self.filelist.count) {
        cell.textLabel.text = @"Create New File/Directory";
        cell.detailTextLabel.text = nil;
        cell.editingAccessoryType = UITableViewCellAccessoryNone;
        
        for (UIGestureRecognizer *rec in cell.gestureRecognizers) {
            rec.enabled = NO;
        }
    } else {
        NSString *filesObjectAtIndex = [self.filelist objectAtIndex:indexPath.row];
        NSString *file = [[kAppDelegate managerCurrentDir]stringByAppendingPathComponent:filesObjectAtIndex];

        cell.textLabel.text = filesObjectAtIndex;
        
        [self verifyProspectiveCopyList];
        
        if ([self.perspectiveCopiedList containsObject:file]) {
            cell.editingAccessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.editingAccessoryType = UITableViewCellAccessoryNone;
        }
        
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

            NSString *detailText = [[[file pathExtension]lowercaseString]isEqualToString:@"zip"]?@"Archive, ":@"File, ";
            
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
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    downloaderAppDelegate *ad = kAppDelegate;
    UITableViewCell *cell = [self.theTableView cellForRowAtIndexPath:indexPath];
    int cellCount = [self.theTableView numberOfRowsInSection:0];
    
    NSString *cellName = cell.textLabel.text;
    NSString *file = [[kAppDelegate managerCurrentDir]stringByAppendingPathComponent:cellName];
    ad.openFile = file;

    BOOL isDir;
    
    if (self.editing) {
        
        if (indexPath.row == cellCount-1) {
            [self showFileCreationAlertView];
        } else {
            if ([self.perspectiveCopiedList containsObject:file]) {
                [self removeItemFromPerspectiveCopyList:file];
                cell.editingAccessoryType = UITableViewCellAccessoryNone;
            } else {
                if ([self addItemToPerspectiveCopyList:file]) {
                    cell.editingAccessoryType = UITableViewCellAccessoryCheckmark;
                } else {
                    cell.editingAccessoryType = UITableViewCellAccessoryNone;
                }
            }
            
            [self updateCopyButtonState];
        }
        
    } else if ([[NSFileManager defaultManager]fileExistsAtPath:file isDirectory:&isDir] && isDir) {
        [self.backButton setHidden:NO];
        [self.homeButton setHidden:NO];
        
        self.navBar.topItem.title = [self.navBar.topItem.title stringByAppendingPathComponent:[file lastPathComponent]];
        
        [kAppDelegate setManagerCurrentDir:file];
        
        [self recalculateDirs];
        
        [self refreshTableViewWithAnimation:UITableViewRowAnimationLeft];
        [self.theTableView flashScrollIndicators];
        
    } else if ([[[file pathExtension]lowercaseString]isEqualToString:@"zip"]) {
        
        [self verifyCopiedList];
        
        UIActionSheet *actionSheet = [[[UIActionSheet alloc]initWithTitle:[NSString stringWithFormat:@"What would you like to do with %@",cellName] completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
            
            NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
            
            if ([title isEqualToString:@"Compress Copied Items"]) {
                if (self.copiedList.count > 0) {
                    
                    [ad showHUDWithTitle:@"Compressing..."];
                    [ad setVisibleHudMode:MBProgressHUDModeIndeterminate];
                    [ad setTagOfVisibleHUD:4];
                    
                    [self compressItems:self.copiedList intoZipFile:[ad.managerCurrentDir stringByAppendingPathComponent:[[actionSheet.title componentsSeparatedByString:@" "]lastObject]]];
                    [self flushCopiedList];
                    [self flushPerspectiveCopyList];
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
        } cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil]autorelease];
        
        actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        
        if (self.copiedList.count > 0) {
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
            dedicatedTextEditor *dte = [dedicatedTextEditor viewController];
            dte.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
            [self presentModalViewController:dte animated:YES];
        } else if ([MIMEUtils isVideoFile:file]) {
            moviePlayerView *mpv = [moviePlayerView viewController];
            mpv.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
            [self presentModalViewController:mpv animated:YES];
        } else if ([MIMEUtils isDocumentFile:file] || isHTML) {
            MyFilesViewDetailViewController *detail = [MyFilesViewDetailViewController viewController];
            detail.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
            [self presentModalViewController:detail animated:YES];
        } else {
            NSString *fileName = [file lastPathComponent];
            NSString *message = [NSString stringWithFormat:@"SwiftLoad cannot identify:\n%@\nPlease select what viewer to open it in.",fileName];
            
            UIActionSheet *sheet = [[UIActionSheet alloc]initWithTitle:message completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
                [self actionSheetAction:actionSheet buttonIndex:buttonIndex];
            } cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Open in Text Editor", @"Open in Movie Player", @"Open in Picture Viewer", @"Open in Audio Player", @"Open in Document Viewer", @"Open In...", nil];
            
            sheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
            [sheet showInView:self.view];
            [sheet release];
        }
    }
    
    [self.theTableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *name = [self.theTableView cellForRowAtIndexPath:indexPath].textLabel.text;
    NSString *file = [[kAppDelegate managerCurrentDir]stringByAppendingPathComponent:name];
    
    if (self.editing) {
        return YES;
    } else {
        BOOL isDir;
        [[NSFileManager defaultManager]fileExistsAtPath:file isDirectory:&isDir];
        return isDir;
    }
}

- (void)editTable {
    [self removeSideSwipeView:NO];
    
    [self reindexFilelist];
    
    if (self.editing) {
        [self.editButton setTitle:@"Edit"];

        if (![[kAppDelegate managerCurrentDir]isEqualToString:kDocsDir]) {
            [self.backButton setHidden:NO];
            [self.homeButton setHidden:NO];
        }

        [super setEditing:NO animated:YES];
        [self.theTableView setEditing:NO animated:YES];
        
        [self.theTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:self.filelist.count inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
        
        for (int i = 0; i < self.filelist.count; i++) {
            UITableViewCell *cell = [self.theTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            [cell setEditing:NO animated:YES];
            cell.editingAccessoryType = UITableViewCellEditingStyleNone;
        }
        [self flushPerspectiveCopyList];
    } else {
        [self.editButton setTitle:@"Done"];
        [self.homeButton setHidden:YES];
        [self.backButton setHidden:YES];
        
        [super setEditing:YES animated:YES];
        [self.theTableView setEditing:YES animated:YES];

        for (int i = 0; i < self.filelist.count; i++) {
            UITableViewCell *cell = [self.theTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            [cell setEditing:YES animated:YES];
        }
        [self.theTableView insertRowsAtIndexPaths:[NSArray arrayWithObjects:[NSIndexPath indexPathForRow:self.filelist.count inSection:0], nil] withRowAnimation:UITableViewRowAnimationLeft];
    }
    [self updateCopyButtonState];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *textLabel = [self.theTableView cellForRowAtIndexPath:indexPath].textLabel.text;
    NSString *file = [[kAppDelegate managerCurrentDir]stringByAppendingPathComponent:textLabel];
    
    BOOL isDir;
    [[NSFileManager defaultManager]fileExistsAtPath:file isDirectory:&isDir];
    
    if (!self.editing || !indexPath) {
        if (isDir) {
            [self removeSideSwipeView:YES];
            return UITableViewCellEditingStyleDelete;
        } else {
            return UITableViewCellEditingStyleNone;
        }
    } else if (self.editing) {
        [self reindexFilelist];
        if (indexPath.row == self.filelist.count) {
            return UITableViewCellEditingStyleInsert;
        }
        return UITableViewCellEditingStyleDelete;
    } else {
        return UITableViewCellEditingStyleNone;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *cellName = [self.theTableView cellForRowAtIndexPath:indexPath].textLabel.text;
        NSString *removePath = [[kAppDelegate managerCurrentDir]stringByAppendingPathComponent:cellName];
        
        [[NSFileManager defaultManager]removeItemAtPath:removePath error:nil];
        [self.filelist removeAllObjects];
        [self.theTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationRight];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        [self showFileCreationAlertView];
    }
}

- (void)createTheFile {
    if ([tv isFirstResponder]) {
        [tv resignFirstResponder];
    }
    
    NSString *thingToBeCreated = [[kAppDelegate managerCurrentDir] stringByAppendingPathComponent:tv.text];
    [[NSFileManager defaultManager]createFileAtPath:thingToBeCreated contents:nil attributes:nil];
    [self refreshTableViewWithAnimation:UITableViewRowAnimationFade];
    [av dismissWithClickedButtonIndex:0 animated:YES];
}

- (void)createTheDir {
    if ([tv isFirstResponder]) {
        [tv resignFirstResponder];
    }

    NSString *thingToBeCreated = [[kAppDelegate managerCurrentDir] stringByAppendingPathComponent:tv.text];
    [[NSFileManager defaultManager]createDirectoryAtPath:thingToBeCreated withIntermediateDirectories:NO attributes:nil error:nil];
    [self refreshTableViewWithAnimation:UITableViewRowAnimationFade];
    [av dismissWithClickedButtonIndex:0 animated:YES];
}

- (void)actionSheetAction:(UIActionSheet *)actionSheet buttonIndex:(int)buttonIndex {
    NSString *file = [kAppDelegate openFile];
    
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }
    
    if (buttonIndex == 0) {
        dedicatedTextEditor *textEditor = [dedicatedTextEditor viewController];
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
        
        [self setDocController:[UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:file]]];
        
        BOOL opened = NO;
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            opened = [self.docController presentOpenInMenuFromRect:self.sideSwipeCell.frame inView:self.theTableView animated:YES];
        } else {
            opened = [self.docController presentOpenInMenuFromRect:self.view.frame inView:self.view animated:YES];
        }
        
        if (!opened) {
            NSString *message = [NSString stringWithFormat:@"No installed applications are capable of opening %@.",[file lastPathComponent]];
            CustomAlertView *avc = [[CustomAlertView alloc]initWithTitle:@"No External Viewers" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [avc show];
            [avc release];
        }
    }
    [self removeSideSwipeView:YES];
}

- (void)touchUpInsideAction:(UIButton *)button {
    NSString *file = [[kAppDelegate managerCurrentDir]stringByAppendingPathComponent:self.sideSwipeCell.textLabel.text];
    [kAppDelegate setOpenFile:file];
    
    int number = button.tag-1;
    
    if (number == 0) {
        NSString *message = [NSString stringWithFormat:@"What would you like to do with %@?",[file lastPathComponent]];
        
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
        
        [popupQuery release];
    } else if (number == 1) {
        
        if (![[DBSession sharedSession]isLinked]) {
            [[DBSession sharedSession]linkFromController:self];
        } else {
            [kAppDelegate uploadLocalFile:file];
        }
        
        [self removeSideSwipeView:YES];
    } else if (number == 2) {
        [kAppDelegate showBTController];
        [self removeSideSwipeView:YES];
    } else if (number == 3) {
        [kAppDelegate sendFileInEmail:file fromViewController:self];
        [self removeSideSwipeView:YES];
        
    } else if (number == 4) {
        NSString *message = [NSString stringWithFormat:@"Are you sure you want to delete %@?",[file lastPathComponent]];
        
        UIActionSheet *popupQuery = [[UIActionSheet alloc]initWithTitle:message completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
            
            if (buttonIndex == actionSheet.destructiveButtonIndex) {
                [[NSFileManager defaultManager]removeItemAtPath:file error:nil];
                [self.filelist removeAllObjects];
                NSIndexPath *indexPath = [self.theTableView indexPathForCell:self.sideSwipeCell];
                [self removeSideSwipeView:NO];
                [self.theTableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationLeft];
            }
            
        } cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"I'm sure, Delete" otherButtonTitles:nil];
        popupQuery.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        [popupQuery showInView:self.view];
        [popupQuery release];
    }
}

- (void)setupSideSwipeView {

    if (self.sideSwipeView == nil) {
        self.sideSwipeView = [[[UIView alloc]initWithFrame:CGRectMake(self.theTableView.frame.origin.x, self.theTableView.frame.origin.y, self.theTableView.frame.size.width, self.theTableView.rowHeight)]autorelease];
        self.sideSwipeView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;

        CGImageRef patternCI = [UIImage imageWithContentsOfFile:getResource(@"dotted-pattern.png")].CGImage;
        UIImage *patternImage = [UIImage imageWithCGImage:patternCI scale:2.0 orientation:UIImageOrientationUp];
        self.sideSwipeView.backgroundColor = [UIColor colorWithPatternImage:patternImage];

        UIImageView *shadowImageView = [[UIImageView alloc]initWithFrame:self.sideSwipeView.bounds];
        shadowImageView.alpha = 0.6;
        shadowImageView.image = [[UIImage imageWithContentsOfFile:getResource(@"inner-shadow.png")]stretchableImageWithLeftCapWidth:0 topCapHeight:0];
        shadowImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self.sideSwipeView addSubview:shadowImageView];
        [shadowImageView release];
        
        UISwipeGestureRecognizer *rightSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeRight:)];
        rightSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
        [self.sideSwipeView addGestureRecognizer:rightSwipeGestureRecognizer];
        [rightSwipeGestureRecognizer release];

        UISwipeGestureRecognizer *leftSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeLeft:)];
        leftSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
        [self.sideSwipeView addGestureRecognizer:leftSwipeGestureRecognizer];
        [leftSwipeGestureRecognizer release];
    }

    for (UIView *view in self.sideSwipeView.subviews) {
        if (![view isKindOfClass:[UIImageView class]]) {
            [view removeFromSuperview];
        }
    }

    NSMutableArray *buttonData = [[NSMutableArray alloc]initWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:@"Action", @"title", @"action.png", @"image", nil], [NSDictionary dictionaryWithObjectsAndKeys:@"FTP", @"title", @"dropbox.png", @"image", nil], [NSDictionary dictionaryWithObjectsAndKeys:@"Bluetooth", @"title", @"bluetooth.png", @"image", nil], [NSDictionary dictionaryWithObjectsAndKeys:@"Email", @"title", @"paperclip.png", @"image", nil], [NSDictionary dictionaryWithObjectsAndKeys:@"Delete", @"title", @"delete.png", @"image", nil], nil];
    
    NSString *filePath = [[kAppDelegate managerCurrentDir]stringByAppendingPathComponent:self.sideSwipeCell.textLabel.text];
    if ([filePath isEqualToString:[kAppDelegate nowPlayingFile]]) {
        [buttonData removeObject:buttonData.lastObject];
    }
    
    for (NSDictionary *buttonInfo in buttonData) {
        UIButton *button = [[UIButton alloc]init];
        button.layer.backgroundColor = [UIColor clearColor].CGColor;
        button.layer.borderColor = [UIColor clearColor].CGColor;
        button.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;

        UIImage *buttonImage = nil;

        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            UIImage *startImage = [UIImage imageWithContentsOfFile:getResource([buttonInfo objectForKey:@"image"])];
            buttonImage = [UIImage imageWithImage:startImage scaledToSize:CGSizeMake(startImage.size.width*1.5, startImage.size.height*1.5)];
        } else {
            buttonImage = [UIImage imageWithContentsOfFile:getResource([buttonInfo objectForKey:@"image"])];
        }

        button.frame = CGRectMake([buttonData indexOfObject:buttonInfo]*((self.sideSwipeView.bounds.size.width)/buttonData.count), 0, ((self.sideSwipeView.bounds.size.width)/buttonData.count), self.sideSwipeView.bounds.size.height);
        
        UIImage *grayImage = [self imageFilledWith:[UIColor colorWithWhite:0.9 alpha:1.0] using:buttonImage];
        [button setImage:grayImage forState:UIControlStateNormal];
        [button setTag:[buttonData indexOfObject:buttonInfo]+1];
        [button addTarget:self action:@selector(touchUpInsideAction:) forControlEvents:UIControlEventTouchUpInside];
        button.imageEdgeInsets = UIEdgeInsetsZero;
        [self.sideSwipeView addSubview:button];
        [button release];
    }
    
    [buttonData release];
}

- (UIImage *)imageFilledWith:(UIColor *)color using:(UIImage *)startImage {
    CGRect imageRect = CGRectMake(0, 0, CGImageGetWidth(startImage.CGImage), CGImageGetHeight(startImage.CGImage));
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(nil, imageRect.size.width, imageRect.size.height, 8, 0, colorSpace, kCGImageAlphaPremultipliedLast);
    
    CGContextClipToMask(context, imageRect, startImage.CGImage);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, imageRect);
    
    CGImageRef newCGImage = CGBitmapContextCreateImage(context);
    UIImage *newImage = [UIImage imageWithCGImage:newCGImage scale:startImage.scale orientation:startImage.imageOrientation];
    CGContextRelease(context);
    CGImageRelease(newCGImage);
    CGColorSpaceRelease(colorSpace);
    return newImage;
}

- (void)swipeLeft:(UISwipeGestureRecognizer *)recognizer {
    [self swipe:recognizer direction:UISwipeGestureRecognizerDirectionLeft];
}

- (void)swipeRight:(UISwipeGestureRecognizer *)recognizer {
    [self swipe:recognizer direction:UISwipeGestureRecognizerDirectionRight];
}

- (void)swipe:(UISwipeGestureRecognizer *)recognizer direction:(UISwipeGestureRecognizerDirection)direction {
    
    if (self.editing) {
        return;
    }
    
    if (recognizer && recognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint location = [recognizer locationInView:self.theTableView];
        NSIndexPath *indexPath = [self.theTableView indexPathForRowAtPoint:location];
        UITableViewCell *cell = [self.theTableView cellForRowAtIndexPath:indexPath];
        
        if (cell.frame.origin.x != 0) {
            [self removeSideSwipeView:YES];
            return;
        }
        
        [self removeSideSwipeView:NO];
        
        if (cell != self.sideSwipeCell && !self.animatingSideSwipe) {
            [self setupSideSwipeView];
            [self addSwipeViewTo:cell direction:direction];
        }
    }
}

- (void)addSwipeViewTo:(UITableViewCell *)cell direction:(UISwipeGestureRecognizerDirection)direction {
    CGRect cellFrame = cell.frame;
    
    [self setSideSwipeCell:cell];
    self.sideSwipeView.frame = CGRectMake(0, cellFrame.origin.y, cellFrame.size.width, cellFrame.size.height);
    [self.theTableView insertSubview:self.sideSwipeView belowSubview:cell];
    self.sideSwipeDirection = direction;
    
    self.animatingSideSwipe = YES;
    
    [UIView animateWithDuration:0.2 animations:^{
        cell.frame = CGRectMake(direction == UISwipeGestureRecognizerDirectionRight?cellFrame.size.width:-cellFrame.size.width, cellFrame.origin.y, cellFrame.size.width, cellFrame.size.height);
    } completion:^(BOOL finished) {
        self.animatingSideSwipe = NO;
    }];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self removeSideSwipeView:NO];
    return indexPath;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self removeSideSwipeView:YES];
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    [self removeSideSwipeView:NO];
    return YES;
}

- (void)removeSideSwipeView:(BOOL)animated {
    
    if (self.animatingSideSwipe) {
        return;
    }
    
    if (!self.sideSwipeCell) {
        return;
    }
    
    if (!self.sideSwipeView) {
        return;
    }
    
    if (animated) {
        
        [UIView animateWithDuration:0.2 animations:^{
            if (self.sideSwipeDirection == UISwipeGestureRecognizerDirectionRight) {
                self.sideSwipeCell.frame = CGRectMake(BOUNCE_PIXELS, self.sideSwipeCell.frame.origin.y, self.sideSwipeCell.frame.size.width, self.sideSwipeCell.frame.size.height);
            } else {
                self.sideSwipeCell.frame = CGRectMake(-BOUNCE_PIXELS, self.sideSwipeCell.frame.origin.y, self.sideSwipeCell.frame.size.width, self.sideSwipeCell.frame.size.height);
            }
            self.animatingSideSwipe = YES;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.2 animations:^{
                if (self.sideSwipeDirection == UISwipeGestureRecognizerDirectionRight) {
                    self.sideSwipeCell.frame = CGRectMake(BOUNCE_PIXELS*2, self.sideSwipeCell.frame.origin.y, self.sideSwipeCell.frame.size.width, self.sideSwipeCell.frame.size.height);
                } else {
                    self.sideSwipeCell.frame = CGRectMake(-BOUNCE_PIXELS*2, self.sideSwipeCell.frame.origin.y, self.sideSwipeCell.frame.size.width, self.sideSwipeCell.frame.size.height);
                }
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.2 animations:^{
                    if (self.sideSwipeDirection == UISwipeGestureRecognizerDirectionRight) {
                        self.sideSwipeCell.frame = CGRectMake(0, self.sideSwipeCell.frame.origin.y, self.sideSwipeCell.frame.size.width, self.sideSwipeCell.frame.size.height);
                    } else {
                        self.sideSwipeCell.frame = CGRectMake(0, self.sideSwipeCell.frame.origin.y, self.sideSwipeCell.frame.size.width, self.sideSwipeCell.frame.size.height);
                    }
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
        
        if (self.sideSwipeView.superview != nil) {
            [self.sideSwipeView removeFromSuperview];
        }
        
        [self setSideSwipeView:nil];
        
        if (self.sideSwipeCell != nil) {
            self.sideSwipeCell.frame = CGRectMake(0, self.sideSwipeCell.frame.origin.y, self.sideSwipeCell.frame.size.width, self.sideSwipeCell.frame.size.height);
            [self setSideSwipeCell:nil];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [self refreshTableViewWithAnimation:UITableViewRowAnimationNone];
    [self.theTableView flashScrollIndicators];
    [self verifyIsCutBOOL];
    [self verifyProspectiveCopyList];
    [self verifyCopiedList];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self flushCopiedList];
    [self flushPerspectiveCopyList];
    self.isCut = NO;
    [self saveIsCutBOOL];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    for (UIView *view in self.view.subviews) {
        if ([view isKindOfClass:[ButtonBarView class]]) {
            [view setNeedsDisplay];
        }
    }

    [self removeSideSwipeView:NO];
    [self setupSideSwipeView];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [self setPerspectiveCopiedList:nil];
    [self setCopiedList:nil];
    [self setDocController:nil];
    [self setFilelist:nil];
    [self setDirs:nil];
    [self setEditButton:nil];
    [self setTheTableView:nil];
    [self setBackButton:nil];
    [self setHomeButton:nil];
    [self setSideSwipeView:nil];
    [self setSideSwipeCell:nil];
    NSLog(@"%@ dealloc'd", NSStringFromClass([self class]));
    [super dealloc];
}

@end
