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

@synthesize dirs, sideSwipeDirection, sideSwipeCell, sideSwipeView, animatingSideSwipe, drawer, drawerCopyButton, drawerPasteButton, editButton, theTableView, folderPathTitle, mtrButton, backButton, homeButton, filelist, movingFileFirst, pastingPath, docController, isCut, copiedList, perspectiveCopiedList;

- (void)pasteInLocation:(NSString *)location {
    for (NSString *oldPath in self.copiedList) {
        NSString *newPath = [location stringByAppendingPathComponent:[oldPath lastPathComponent]];
        NSError *error = nil;
        
        if (self.isCut) {
            [[NSFileManager defaultManager]moveItemAtPath:oldPath toPath:newPath error:&error];
        } else {
            [[NSFileManager defaultManager]copyItemAtPath:oldPath toPath:newPath error:&error];
        }
        
        if (error) {
            NSLog(@"error: %@ \n for file: %@",error, oldPath);
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
    
    NSMutableDictionary *changedDict = [[(NSDictionary *)notif mutableCopy]autorelease];
    
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

- (IBAction)showCopyPasteController {
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
        [self.copyAndPasteButton setHidden:YES];
        return;
    }
    
    [self verifyProspectiveCopyList];
    [self verifyCopiedList];
    
    BOOL persCLGT = (self.perspectiveCopiedList.count > 0);
    BOOL CLGT = (self.copiedList.count > 0);
    BOOL shouldUnhide = ((persCLGT || CLGT) || (persCLGT && CLGT));
    
    [self.copyAndPasteButton setHidden:!shouldUnhide];
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
    indexOfCheckmark = -1;
    [self.filelist removeAllObjects];
    [self.theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:rowAnim];
}

- (void)inflate:(NSString *)file {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    ZipFile *unzipFile = [[ZipFile alloc] initWithFileName:file mode:ZipFileModeUnzip];
    NSArray *infos = [unzipFile listFileInZipInfos];
    
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
        NSString *dash = [info.name substringFromIndex:[info.name length]-1];
        BOOL hasSlash = [dash isEqualToString:@"/"];
        
        if (hasSlash) {
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
    
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [self refreshTableViewWithAnimation:UITableViewRowAnimationNone];
    
    [pool release];
}

- (void)compress:(NSArray *)objects {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    NSString *theFile = [objects objectAtIndex:0]; // file to add
    NSString *file = [objects objectAtIndex:1]; // zip file
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
    
    [self setMovingFileFirst:nil];

    [self.mtrButton setHidden:YES];
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
    
    tv = [[UITextField alloc]initWithFrame:CGRectMake(43, 48, 200, 31)];
    [tv becomeFirstResponder];
    [tv setKeyboardAppearance:UIKeyboardAppearanceAlert];
    [tv setBorderStyle:UITextBorderStyleBezel];
    [tv setBackgroundColor:[UIColor whiteColor]];
    [tv setReturnKeyType:UIReturnKeyDone];
    [tv setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [tv setAutocorrectionType:UITextAutocorrectionTypeNo];
    [tv setPlaceholder:@"File/Directory Name"];
    [tv setFont:[UIFont boldSystemFontOfSize:18]];
    [tv setAdjustsFontSizeToFitWidth:YES];
    tv.clearButtonMode = UITextFieldViewModeWhileEditing;
    
    [av addSubview:createFile];
    [av addSubview:createDir];
    [av addSubview:tv];
    [av show];
    [av release];
    [tv release];
    [createFile release];
    [createDir release];
}

- (void)recalculateDirs {
    
    if (self.dirs == nil) {
        self.dirs = [NSMutableArray array];
    }
    
    [self.dirs removeAllObjects];
    
    NSString *dirdisp = self.folderPathTitle.text;
    
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

- (IBAction)goBackDir {  
    [self removeSideSwipeView:NO];

    [self recalculateDirs];

    NSString *prevDir = [self.dirs lastObject];
    
    [kAppDelegate setManagerCurrentDir:prevDir];
    [self.dirs removeObject:[self.dirs lastObject]];
    
    NSString *oldTfPath = self.folderPathTitle.text;
    NSString *newTfPath = [oldTfPath stringByDeletingLastPathComponent];
    [self.folderPathTitle setText:newTfPath];

    if ([prevDir isEqualToString:kDocsDir]) {
        [self.backButton setHidden:YES];
        [self.homeButton setHidden:YES];
    }

    [self refreshTableViewWithAnimation:UITableViewRowAnimationRight];
}

- (IBAction)moveFileToRoot {
    NSString *theCorrectFile = [[kAppDelegate managerCurrentDir] stringByAppendingPathComponent:self.movingFileFirst];
    NSString *docsDirPlusFile = [kDocsDir stringByAppendingPathComponent:self.movingFileFirst];
    [[NSFileManager defaultManager]moveItemAtPath:theCorrectFile toPath:docsDirPlusFile error:nil];
    
    [self.theTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexOfCheckmark inSection:0]].editingAccessoryType = UITableViewCellAccessoryNone;
    
    [self refreshTableViewWithAnimation:UITableViewRowAnimationFade];
    [self.mtrButton setHidden:YES];
    [self setMovingFileFirst:nil];
}

- (IBAction)goHome {
    [self removeSideSwipeView:NO];
    
    [self.dirs removeAllObjects];
    [self.folderPathTitle setText:@"/"];
    [self.backButton setHidden:YES];
    
    [kAppDelegate setManagerCurrentDir:kDocsDir];

    [self.homeButton setHidden:YES];
    
    [self refreshTableViewWithAnimation:UITableViewRowAnimationRight];
    [self.theTableView setContentOffset:CGPointMake(0, 0)];
}

- (IBAction)back {
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

- (void)setDrawerShadow {
    self.drawer.layer.cornerRadius = 5;
    self.drawer.layer.shadowRadius = 0.3;
    self.drawer.layer.shadowColor = [UIColor blackColor].CGColor;
    self.drawer.layer.shadowOpacity = 0.5f;
    self.drawer.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
    self.drawer.layer.shadowRadius = 5.0f;
    self.drawer.layer.shadowPath = [UIBezierPath bezierPathWithRect:CGRectMake(-1, -1, drawer.frame.size.width+2, drawer.frame.size.height+2)].CGPath;
}

- (void)viewDidLoad {       
    [super viewDidLoad];
    
    UIImage *bbiImage = [getButtonImage() resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)];
    [self.editButton setBackgroundImage:bbiImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.theTableView.rowHeight = 60;
    } 
    
    PullToRefreshView *pull = [[PullToRefreshView alloc]initWithScrollView:self.theTableView];
    [pull setDelegate:self];
    [self.theTableView addSubview:pull];
    [pull release];

    [kAppDelegate setManagerCurrentDir:kDocsDir];

    [self.folderPathTitle setText:@"/"];
    
    animatingSideSwipe = NO;
    indexOfCheckmark = -1;
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(copiedListChanged:) name:@"copiedlistchanged" object:nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    [self reindexFilelist];
    
    if (self.editing){
        return self.filelist.count+1;
    } else {
        return self.filelist.count;
    }
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
        
        DTCustomColoredAccessory *accessory = [DTCustomColoredAccessory accessoryWithColor:cell.textLabel.textColor];
        accessory.accessoryColor = [UIColor whiteColor];
        accessory.highlightedColor = [UIColor darkGrayColor];
        [accessory addTarget:self action:@selector(accessoryButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        cell.accessoryView = accessory;
    
        float height = (cell.bounds.size.height)/2;
            
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            cell.accessoryView.center = CGPointMake(735, height);
            cell.textLabel.font = [UIFont fontWithName:@"MarkerFelt-Thin" size:27];
            cell.detailTextLabel.font = [UIFont systemFontOfSize:20.0];
        } else {
            cell.accessoryView.center = CGPointMake(297.5, height);
            cell.textLabel.font = [UIFont fontWithName:@"MarkerFelt-Thin" size:20];
        }

        cell.detailTextLabel.textColor = [UIColor blackColor];
    }
    
   /* if (indexOfCheckmark == indexPath.row) {
        cell.editingAccessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.editingAccessoryType = UITableViewCellAccessoryNone;
    }*/
    
    cell.editingAccessoryType = UITableViewCellAccessoryNone;
    
    for (UIGestureRecognizer *rec in cell.gestureRecognizers) {
        [cell removeGestureRecognizer:rec];
    }

    if (self.editing && indexPath.row == self.filelist.count) {
        cell.textLabel.text = @"Create New File/Directory";
        cell.detailTextLabel.text = nil;
    } else {
        NSString *filesObjectAtIndex = [self.filelist objectAtIndex:indexPath.row];
        NSString *file = [[kAppDelegate managerCurrentDir]stringByAppendingPathComponent:filesObjectAtIndex];

        cell.textLabel.text = filesObjectAtIndex;
        
        BOOL isZip = [[[file pathExtension]lowercaseString] isEqualToString:@"zip"];
        BOOL isDir;    
        BOOL exists = [[NSFileManager defaultManager]fileExistsAtPath:file isDirectory:&isDir];
        
        if ([self.perspectiveCopiedList containsObject:cell.textLabel.text]) {
            cell.editingAccessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.editingAccessoryType = UITableViewCellAccessoryNone;
        }

        if (exists && isDir) {
            cell.detailTextLabel.text = @"Directory";
        } else {
            UISwipeGestureRecognizer *rightSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
            rightSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
            [cell addGestureRecognizer:rightSwipeGestureRecognizer];
            [rightSwipeGestureRecognizer release];
            
            UISwipeGestureRecognizer *leftSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft:)];
            leftSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
            [cell addGestureRecognizer:leftSwipeGestureRecognizer];
            [leftSwipeGestureRecognizer release];
            
            
            NSString *detailTextLabelMe = nil;
            if (isZip == YES) {
                detailTextLabelMe = @"Archive, ";
            } else {
                detailTextLabelMe = @"File, ";
            }
            
            float fileSize = fileSize(file);
            
            if (fileSize < 1024.0) {
                detailTextLabelMe = [detailTextLabelMe stringByAppendingFormat:@"%.0f Bytes",fileSize];
                if (fileSize == 1) {
                    detailTextLabelMe = [detailTextLabelMe substringToIndex:(detailTextLabelMe.length-1)];
                }
            } else if (fileSize < (1024*1024) && fileSize > 1024.0 ) {
                fileSize = fileSize/1014;
                detailTextLabelMe = [detailTextLabelMe stringByAppendingFormat:@"%.0f KB",fileSize];
            } else if (fileSize < (1024*1024*1024) && fileSize > (1024*1024)) {
                fileSize = fileSize/(1024*1024);
                detailTextLabelMe = [detailTextLabelMe stringByAppendingFormat:@"%.0f MB",fileSize];                
            }
            cell.detailTextLabel.text = detailTextLabelMe;
        }
    }

    cell.textLabel.backgroundColor = [UIColor clearColor];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    downloaderAppDelegate *ad = kAppDelegate;
    UITableViewCell *cell = [self.theTableView cellForRowAtIndexPath:indexPath];

    int cellCount = [self.theTableView numberOfRowsInSection:0];
    
    if (self.editing) {
        cellCount = cellCount-1;
    }

    if (self.editing && indexPath.row == cellCount) {
        [self showFileCreationAlertView];
    } else if (indexPath.row != cellCount) {
        NSString *cellName = cell.textLabel.text;
        NSString *file = [[kAppDelegate managerCurrentDir]stringByAppendingPathComponent:cellName];

        [kAppDelegate setOpenFile:file];
        
        BOOL result = [[[file pathExtension]lowercaseString]isEqualToString:@"zip"];
        BOOL isDir;    
        BOOL directoryExists = [[NSFileManager defaultManager]fileExistsAtPath:file isDirectory:&isDir];
    
        if (self.editing) {
            
            if ([self.perspectiveCopiedList containsObject:file]) {
                // remove the checkmark
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
            
            /*if (self.movingFileFirst.length == 0) {
                [tableView cellForRowAtIndexPath:indexPath].editingAccessoryType = UITableViewCellAccessoryCheckmark;
                indexOfCheckmark = indexPath.row;
                
                [self setMovingFileFirst:cellName];

                BOOL isDocsDir = [[kAppDelegate managerCurrentDir] isEqualToString:kDocsDir];
                
                if (isDocsDir == NO) {
                    [self.mtrButton setHidden:NO];
                }  
                
            } else {
                NSString *folderDest = cellName;
                NSString *theFile = [[kAppDelegate managerCurrentDir] stringByAppendingPathComponent:self.movingFileFirst];
                NSString *theDestFolder = [[kAppDelegate managerCurrentDir] stringByAppendingPathComponent:folderDest];
                NSString *theDest = [theDestFolder stringByAppendingPathComponent:self.movingFileFirst];
                
                BOOL destIsADir;
                BOOL existsAtDest = [[NSFileManager defaultManager]fileExistsAtPath:theDest isDirectory:&destIsADir];
                
                if ([theFile isEqualToString:theDestFolder]) {
                    [self.theTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexOfCheckmark inSection:0]].editingAccessoryType = UITableViewCellAccessoryNone;
                    [self setMovingFileFirst:nil];
                    [self.mtrButton setHidden:YES];
                } else if (existsAtDest && !destIsADir) {
                    NSString *destRelative = [[theDest stringByReplacingOccurrencesOfString:kDocsDir withString:@""]stringByDeletingLastPathComponent];
                    NSString *message = [NSString stringWithFormat:@"The file \"%@\" already exists at %@.",self.movingFileFirst,destRelative];
                    CustomAlertView *av1 = [[CustomAlertView alloc]initWithTitle:@"File Exists" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [av1 show];
                    [av1 release];
                } else if (isDir) { // move to new dir code (the newest cell click is a dir)
                    [self.theTableView deselectRowAtIndexPath:indexPath animated:NO];
                    [[NSFileManager defaultManager]moveItemAtPath:theFile toPath:theDest error:nil];
                    [self setMovingFileFirst:nil];
                    [self.mtrButton setHidden:YES];
                    [self refreshTableViewWithAnimation:UITableViewRowAnimationFade];
                } else if (result) {
                    NSArray *objects = [[NSArray alloc]initWithObjects:theFile, file, nil];
                    MBProgressHUD *HUD = [[MBProgressHUD alloc]initWithView:ad.window];
                    [ad.window addSubview:HUD];
                    HUD.delegate = self;
                    HUD.mode = MBProgressHUDModeIndeterminate;
                    HUD.labelText = @"Compressing...";
                    [HUD showWhileExecuting:@selector(compress:) onTarget:self withObject:objects animated:YES];
                    [HUD release];
                    [objects release];
                } 
             }*/
    } else if (directoryExists && isDir) { 
        [self.backButton setHidden:NO];
        [self.homeButton setHidden:NO];
        
        [self.folderPathTitle setText:[self.folderPathTitle.text stringByAppendingPathComponent:[file lastPathComponent]]];
        
        [kAppDelegate setManagerCurrentDir:file];
        
        [self recalculateDirs];
        
        [self refreshTableViewWithAnimation:UITableViewRowAnimationLeft];
        [self.theTableView flashScrollIndicators];
        
    } else if (result) {
        if (fileSize(file) > 0) {
            HUDZ = [[MBProgressHUD alloc]initWithView:ad.window];
            [ad.window addSubview:HUDZ];
            HUDZ.delegate = self;
            HUDZ.mode = MBProgressHUDModeDeterminate;
            HUDZ.labelText = @"Inflating...";
            HUDZ.detailsLabelText = [file lastPathComponent];
            [HUDZ showWhileExecuting:@selector(inflate:) onTarget:self withObject:file animated:YES];
            [HUDZ release];
        }
    } else {
        BOOL isHTML = [MIMEUtils isHTMLFile:file];
        
        if ([MIMEUtils isAudioFile:file]) {
            AudioPlayerViewController *audio = [[AudioPlayerViewController alloc]initWithAutoNib];
            audio.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
            [self presentModalViewController:audio animated:YES];
            [audio release];
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
            } cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Open In Text Editor", @"Open In Movie Player", @"Open In Picture Viewer", @"Open In Audio Player", @"Open In Document Viewer", @"Open In...", nil];
            
            sheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
            [sheet showInView:self.view];
            [sheet release];
        }
    }
    }
    [self.theTableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *name = [self.theTableView cellForRowAtIndexPath:indexPath].textLabel.text;
    NSString *file = [[kAppDelegate managerCurrentDir] stringByAppendingPathComponent:name];
    
    BOOL isDir;
    [[NSFileManager defaultManager]fileExistsAtPath:file isDirectory:&isDir];
    
    if (self.editing) {
        return YES;
    } else {
        if (isDir) {
            return YES;
        } else {  
            return NO;
        }
    }
}

- (IBAction)editTable {
    [self removeSideSwipeView:NO];
    
    [self reindexFilelist];
    
    if (self.editing) {
        [self.editButton setTitle:@"Edit"];
        [self.mtrButton setHidden:YES];

        if (![[kAppDelegate managerCurrentDir] isEqualToString:kDocsDir]) {
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
        indexOfCheckmark = -1;
        [self setMovingFileFirst:nil];
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

    [self reindexFilelist];

    NSString *textLabel = [self.theTableView cellForRowAtIndexPath:indexPath].textLabel.text;
    NSString *file = [[kAppDelegate managerCurrentDir] stringByAppendingPathComponent:textLabel];
    
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
        
        [self reindexFilelist];
        
        NSString *cellName = [self.theTableView cellForRowAtIndexPath:indexPath].textLabel.text;
        NSString *removePath = [[kAppDelegate managerCurrentDir] stringByAppendingPathComponent:cellName];
        
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

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (event.type == UIEventSubtypeMotionShake) {
        [self refreshTableViewWithAnimation:UITableViewRowAnimationFade];
        [self.theTableView flashScrollIndicators];
    }
}

- (void)hideDrawerSubviews:(BOOL)hide {
    for (UIView *view in drawer.subviews) {
        [view setHidden:hide];
    }
}

- (void)hideTheDrawer {
    CGRect hiddenRect = CGRectMake(66, 0, 193, 44);
    [self performSelector:@selector(hideTheDamnThing) withObject:nil afterDelay:0.61];
    [self hideDrawerSubviews:YES];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationDelay:0.1];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [self setDrawerShadow];
    [self.drawer setFrame:hiddenRect];
    [self setDrawerShadow];
    [UIView commitAnimations];
    [self setDrawerShadow];
    for (UIView *view in self.view.subviews) {
        view.userInteractionEnabled = YES;
    }
}

- (IBAction)copyTheFile {
    NSString *copyString = [[kAppDelegate managerCurrentDir]stringByAppendingPathComponent:self.movingFileFirst];
    [self refreshTableViewWithAnimation:UITableViewRowAnimationNone];
    [self setPastingPath:copyString];
    [self hideTheDrawer];
}

- (IBAction)pasteTheFile {
    NSString *pastePath = [[kAppDelegate managerCurrentDir] stringByAppendingPathComponent:[self.pastingPath lastPathComponent]];
    
    if ([[NSFileManager defaultManager]fileExistsAtPath:pastePath]) {
        NSString *lpc = [self.pastingPath lastPathComponent];
        NSString *ext = [lpc pathExtension];
        NSString *justName = [lpc stringByDeletingPathExtension];
        NSString *newFilename = [[justName stringByAppendingString:@" (copy)."]stringByAppendingString:ext];
        pastePath = [[kAppDelegate managerCurrentDir]stringByAppendingPathComponent:newFilename];
    }
    
    [[NSFileManager defaultManager]copyItemAtPath:self.pastingPath toPath:pastePath error:nil];
    [self setPastingPath:nil];
    
    [self refreshTableViewWithAnimation:UITableViewRowAnimationFade];
    [self hideTheDrawer];
}

- (void)hideTheDamnThing {
    [self.drawer setHidden:YES];
    [self setDrawerShadow];
    for (UIView *view in self.view.subviews) {
        view.userInteractionEnabled = YES;
    }
}

- (void)unhideAnimation {
    [self hideDrawerSubviews:NO];
    
    for (UIView *view in self.view.subviews) {
        view.userInteractionEnabled = NO;
        if (view.tag == 1) {
            view.userInteractionEnabled = YES;
        }
    }
    
    self.drawer.userInteractionEnabled = YES;
    self.drawerCopyButton.userInteractionEnabled = YES;
    self.drawerPasteButton.userInteractionEnabled = YES;
}

- (IBAction)toggleDrawer {
    
    CGRect hiddenRect = CGRectMake(66, 0, 193, 44);
    CGRect visibleRect = CGRectMake(66, 41, 193, 121);
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        hiddenRect = CGRectMake(288, 0, 193, 44);
        visibleRect = CGRectMake(288, 41, 193, 121);
    }

    if (self.editing && self.movingFileFirst.length > 0) {
        [self.drawerCopyButton setEnabled:YES];
        [self.drawerCopyButton setAlpha:1.0];
    } else {
        [self.drawerCopyButton setEnabled:NO];
        [self.drawerCopyButton setAlpha:0.5];
    }
    
    if (self.pastingPath.length > 0) {
        [self.drawerPasteButton setEnabled:YES];
        [self.drawerPasteButton setAlpha:1.0];
    } else {
        [self.drawerPasteButton setEnabled:NO];
        [self.drawerPasteButton setAlpha:0.5];
    }

    if (CGRectEqualToRect(hiddenRect, self.drawer.frame)) {
        [self.drawer setHidden:NO];
        [self hideDrawerSubviews:YES];
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.3];
        [UIView setAnimationDelay:0.0];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(unhideAnimation)];
        [self setDrawerShadow];
        [self.drawer setFrame:visibleRect];
        [self setDrawerShadow];
        [UIView commitAnimations];
    } else {
        [self hideDrawerSubviews:YES];
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.3];
        [UIView setAnimationDelay:0.0];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(hideTheDamnThing)];
        [self setDrawerShadow];
        [self.drawer setFrame:hiddenRect];
        [self setDrawerShadow];
        [UIView commitAnimations];
    }
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    CGPoint location = [[[event allTouches]anyObject] locationInView:self.view];
    
    CGRect hiddenRect = CGRectMake(66, 0, 193, 44);
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        hiddenRect = CGRectMake(288, 0, 193, 44);
    }
  
    if (!CGRectContainsPoint(self.drawer.frame, location) && !CGRectEqualToRect(hiddenRect, self.drawer.frame)) {
        [self toggleDrawer];
    }
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
        
        BOOL opened;
        
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


// slide to reveal actions

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)touchUpInsideAction:(UIButton *)button {
    NSString *file = [[kAppDelegate managerCurrentDir] stringByAppendingPathComponent:self.sideSwipeCell.textLabel.text];
    
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
        BOOL sendsMail = [MFMailComposeViewController canSendMail];
        if (sendsMail == NO) {
            CustomAlertView *avf = [[CustomAlertView alloc]initWithTitle:@"Mail Unavailable" message:@"In order to use this functionality, you must set up an email account in Settings." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [avf show];
            [avf release];
        } else if (sendsMail == YES) {
            MFMailComposeViewController *controller = [[MFMailComposeViewController alloc]init];
            controller.mailComposeDelegate = self;
            [controller setSubject:@"Your file"];
            NSData *myData = [[NSData alloc]initWithContentsOfFile:file];
            [controller addAttachmentData:myData mimeType:[MIMEUtils fileMIMEType:file] fileName:[file lastPathComponent]];
            [controller setMessageBody:@"" isHTML:NO];
            [self presentModalViewController:controller animated:YES];
            [controller release];
            [myData release];
        }
        [self removeSideSwipeView:YES];
        
    } else if (number == 4) {
        NSString *message = [NSString stringWithFormat:@"Are you sure you want to delete %@?",[file lastPathComponent]];
        
        UIActionSheet *popupQuery = [[UIActionSheet alloc]initWithTitle:message completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
            
            if (buttonIndex == actionSheet.destructiveButtonIndex) {
                
                [self reindexFilelist];
                
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
        UIView *selfSwipeViewTempAlloc = [[UIView alloc]initWithFrame:CGRectMake(self.theTableView.frame.origin.x, self.theTableView.frame.origin.y, self.theTableView.frame.size.width, self.theTableView.rowHeight)];
        [self setSideSwipeView:selfSwipeViewTempAlloc];
        [selfSwipeViewTempAlloc release];
        
        self.sideSwipeView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
        
        UIImage *patternImage = [[UIImage alloc]initWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"dotted-pattern@2x" ofType:@"png"]];
        CGImageRef patternCI = patternImage.CGImage;
        UIImage *patternImageScaled = [[UIImage alloc]initWithCGImage:patternCI scale:2.0 orientation:UIImageOrientationUp];
        [patternImage release];
        self.sideSwipeView.backgroundColor = [UIColor colorWithPatternImage:patternImageScaled];
        [patternImageScaled release];
        
        UIImage *shadowNonStretchedImage = [[UIImage alloc]initWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"inner-shadow" ofType:@"png"]];
        UIImage *shadow = [shadowNonStretchedImage stretchableImageWithLeftCapWidth:0 topCapHeight:0];
        
        [shadowNonStretchedImage release];
        
        UIImageView *shadowImageView = [[UIImageView alloc]initWithFrame:self.sideSwipeView.bounds];
        shadowImageView.alpha = 0.6;
        shadowImageView.image = shadow;
        shadowImageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
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

        NSString *imagePathRetina = [[[[[NSBundle mainBundle]bundlePath] stringByAppendingPathComponent:[buttonInfo objectForKey:@"image"]] stringByDeletingPathExtension]stringByAppendingString:@"@2x.png"];
        
        UIImage *buttonImage = nil;

        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            CGFloat multiplier = 1.5;
            UIImage *startImage = [UIImage imageWithContentsOfFile:imagePathRetina];
            CGSize newFrame = CGSizeMake(startImage.size.width*multiplier, startImage.size.height*multiplier);
            buttonImage = [UIImage imageWithImage:startImage scaledToSize:newFrame];
        } else {
            buttonImage = [UIImage imageWithContentsOfFile:imagePathRetina];
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
        
        if (cell != self.sideSwipeCell && !animatingSideSwipe) {
            [self setSideSwipeCell:cell];
            [self setupSideSwipeView];
            [self addSwipeViewTo:cell direction:direction];
        }
    }
}

- (void)addSwipeViewTo:(UITableViewCell *)cell direction:(UISwipeGestureRecognizerDirection)direction {
    CGRect cellFrame = cell.frame;
    
    [self setSideSwipeCell:cell];
    self.sideSwipeView.frame = cellFrame;
    [self.theTableView insertSubview:sideSwipeView belowSubview:cell];
    self.sideSwipeDirection = direction;
    
    self.sideSwipeView.frame = CGRectMake(0, cellFrame.origin.y, cellFrame.size.width, cellFrame.size.height);
    
    animatingSideSwipe = YES;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.2];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStopAddingSwipeView:finished:context:)];

    cell.frame = CGRectMake(direction == UISwipeGestureRecognizerDirectionRight ? cellFrame.size.width : -cellFrame.size.width, cellFrame.origin.y, cellFrame.size.width, cellFrame.size.height);
    
    [UIView commitAnimations];
}

- (void)animationDidStopAddingSwipeView:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    animatingSideSwipe = NO;
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
    
    if (animatingSideSwipe) {
        return;
    }
    
    if (!self.sideSwipeCell) {
        return;
    }
    
    if (!self.sideSwipeView) {
        return;
    }
    
    if (animated) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.2];
        if (self.sideSwipeDirection == UISwipeGestureRecognizerDirectionRight) {
            self.sideSwipeCell.frame = CGRectMake(BOUNCE_PIXELS, self.sideSwipeCell.frame.origin.y, self.sideSwipeCell.frame.size.width, self.sideSwipeCell.frame.size.height);
        } else {
            self.sideSwipeCell.frame = CGRectMake(-BOUNCE_PIXELS, self.sideSwipeCell.frame.origin.y, self.sideSwipeCell.frame.size.width, self.sideSwipeCell.frame.size.height);
        }
        animatingSideSwipe = YES;
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(animationDidStopOne:finished:context:)];
        [UIView commitAnimations];
    } else {
        animatingSideSwipe = NO;
        
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

- (void)animationDidStopOne:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.2];
    if (self.sideSwipeDirection == UISwipeGestureRecognizerDirectionRight) {
        self.sideSwipeCell.frame = CGRectMake(BOUNCE_PIXELS*2, self.sideSwipeCell.frame.origin.y, self.sideSwipeCell.frame.size.width, self.sideSwipeCell.frame.size.height);
    } else {
        self.sideSwipeCell.frame = CGRectMake(-BOUNCE_PIXELS*2, self.sideSwipeCell.frame.origin.y, self.sideSwipeCell.frame.size.width, self.sideSwipeCell.frame.size.height);
    }
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStopTwo:finished:context:)];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    [UIView commitAnimations];
}

- (void)animationDidStopTwo:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    [UIView commitAnimations];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.2];
    if (self.sideSwipeDirection == UISwipeGestureRecognizerDirectionRight) {
        self.sideSwipeCell.frame = CGRectMake(0, self.sideSwipeCell.frame.origin.y, self.sideSwipeCell.frame.size.width, self.sideSwipeCell.frame.size.height);
    } else {
        self.sideSwipeCell.frame = CGRectMake(0, self.sideSwipeCell.frame.origin.y, self.sideSwipeCell.frame.size.width, self.sideSwipeCell.frame.size.height);
    }
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStopThree:finished:context:)];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    [UIView commitAnimations];
}

- (void)animationDidStopThree:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    animatingSideSwipe = NO;
    [self removeSideSwipeView:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [self refreshTableViewWithAnimation:UITableViewRowAnimationNone];
    [self.theTableView flashScrollIndicators];
    [self verifyIsCutBOOL];
    [self verifyProspectiveCopyList];
    [self verifyCopiedList];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self resignFirstResponder];
    [self saveCopiedList];
    [self flushPerspectiveCopyList];
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

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self removeSideSwipeView:NO];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [self setPerspectiveCopiedList:nil];
    [self setCopiedList:nil];
    [self setDocController:nil];
    [self setMovingFileFirst:nil];
    [self setFilelist:nil];
    [self setDirs:nil];
    [self setDrawer:nil];
    [self setDrawerCopyButton:nil];
    [self setDrawerPasteButton:nil];
    [self setEditButton:nil];
    [self setTheTableView:nil];
    [self setFolderPathTitle:nil];
    [self setMtrButton:nil];
    [self setBackButton:nil];
    [self setHomeButton:nil];
    [self setSideSwipeView:nil];
    [self setSideSwipeCell:nil];
    NSLog(@"%@ dealloc'd", NSStringFromClass([self class]));
    [super dealloc];
}

@end
