//
//  downloaderAppDelegate.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 8/11/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import "AppDelegate.h"

NSString * const NSFileName = @"NSFileName";
NSString * const kCopyListChangedNotification = @"copiedlistchanged";

float systemVersion(void) {
    static float systemVersion = -1;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        systemVersion = [UIDevice currentDevice].systemVersion.floatValue;
    });
    return systemVersion;
}

void fireFinishDLNotification(NSString *filename) {
    [[NetworkActivityController sharedController]hideIfPossible];
    
    if (filename.length > 14) {
        filename = [[filename substringToIndex:11]stringByAppendingString:@"..."];
    }
    
    UILocalNotification *notification = [[UILocalNotification alloc]init];
    notification.fireDate = [NSDate date];
    notification.alertBody = [NSString stringWithFormat:@"Finished downloading: %@",filename];
    notification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication]presentLocalNotificationNow:notification];
}

NSString * getResource(NSString *raw) {
    return [[NSBundle mainBundle]pathForResource:[raw stringByDeletingPathExtension] ofType:[raw pathExtension]];
}

float sanitizeMesurement(float measurement) {
    return ((measurement/460)*[[UIScreen mainScreen]applicationFrame].size.height);
}

NSString * getNonConflictingFilePathForPath(NSString *path) {
    NSString *oldPath = path;
    NSString *ext = [path pathExtension];
    int appendNumber = 1;
    
    do {
        if (![[NSFileManager defaultManager]fileExistsAtPath:path]) {
            break;
        }
        
        path = [[oldPath stringByDeletingPathExtension]stringByAppendingString:[NSString stringWithFormat:@" - %d",appendNumber]];
        
        if (ext.length > 0) {
            path = [path stringByAppendingPathExtension:ext];
        }
        
        appendNumber = appendNumber+1;
    } while (YES);
    
    return path;
}

@implementation AppDelegate

//
// Audio Player
//

- (NSArray *)artworksForFileAtPath:(NSString *)path {
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:path] options:nil];
    
    NSArray *artworks = [AVMetadataItem metadataItemsFromArray:asset.commonMetadata withKey:AVMetadataCommonKeyArtwork keySpace:AVMetadataKeySpaceCommon];
    
    NSMutableArray *artworkImages = [NSMutableArray array];
    for (AVMetadataItem *item in artworks) {
        NSString *keySpace = item.keySpace;
        
        UIImage *image = nil;
        
        if ([keySpace isEqualToString:AVMetadataKeySpaceID3]) {
            image = [UIImage imageWithData:((NSDictionary *)item.value)[@"data"]];
        } else if ([keySpace isEqualToString:AVMetadataKeySpaceiTunes]) {
            image = [UIImage imageWithData:(NSData *)item.value];
        }
        
        if (image != nil) {
            [artworkImages addObject:image];
        }
    }
    
    return artworkImages;
}

- (void)loadMetadataForFile:(NSString *)file {
    NSDictionary *id3 = [ID3Editor loadTagFromFile:file];
    NSString *artist = id3[@"artist"];
    NSString *title = id3[@"title"];
    NSString *album = id3[@"album"];
    NSString *metadata = [NSString stringWithFormat:@"%@\n%@\n%@",artist,title,album];
    [AudioPlayerViewController notif_setInfoFieldText:metadata];
    
    if ([artist isEqualToString:@"-"]) {
        artist = @"";
    }
    
    if ([title isEqualToString:@"-"]) {
        title = @"";
    }
    
    if ([album isEqualToString:@"-"]) {
        album = @"";
    }
    
    if (artist.length == 0 && title.length == 0 && album.length == 0) {
        artist = @"";
        title = file.lastPathComponent;
        album = @"";
    }
    
    NSDictionary *songInfo = [@{ MPMediaItemPropertyArtist:artist, MPMediaItemPropertyTitle:title, MPMediaItemPropertyAlbumTitle:album } mutableCopy];
    
    NSArray *artworkImages = [self artworksForFileAtPath:file];

    [AudioPlayerViewController notif_setAlbumArt:nil];
    
    if (artworkImages.count > 0) {
        UIImage *image = artworkImages[0];
        if (image != nil) {
            [AudioPlayerViewController notif_setAlbumArt:image];
            [songInfo setValue:[[MPMediaItemArtwork alloc]initWithImage:image] forKey:MPMediaItemPropertyArtwork];
        }
    }
    
    [[MPNowPlayingInfoCenter defaultCenter]setNowPlayingInfo:songInfo];
}

- (void)togglePlayPause {
    if (!_audioPlayer.isPlaying) {
        [_audioPlayer play];
        self.nowPlayingFile = [_openFile copy];
        [AudioPlayerViewController notif_setPausePlayTitlePause];
        [AudioPlayerViewController notif_setShouldUpdateTime:YES];
    } else {
        [_audioPlayer pause];
        [AudioPlayerViewController notif_setPausePlayTitlePlay];
        [AudioPlayerViewController notif_setShouldUpdateTime:NO];
    }
}

- (void)playFile:(NSString *)file {
    NSString *currentDir = [file stringByDeletingLastPathComponent];
    
    NSArray *filesOfDir = [[[NSFileManager defaultManager]contentsOfDirectoryAtPath:currentDir error:nil]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSMutableArray *audioFiles = [NSMutableArray array];
    
    for (NSString *filename in filesOfDir) {
        if ([MIMEUtils isAudioFile:filename]) {
            [audioFiles addObject:[currentDir stringByAppendingPathComponent:filename]];
        }
    }
    
    NSError *playingError = nil;
    
    if (![file isEqualToString:_nowPlayingFile]) {
        [_audioPlayer stop];
        self.audioPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:file] error:&playingError];
        [_audioPlayer setDelegate:self];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            [_audioPlayer prepareToPlay];
            dispatch_sync(dispatch_get_main_queue(), ^{
                @autoreleasepool {
                    [_audioPlayer play];
                    [AudioPlayerViewController notif_setPausePlayTitlePause];
                    self.nowPlayingFile = file;
                }
            });
        }
    });
    
    if (!playingError) {
        [self loadMetadataForFile:file];
    }
    
    [AudioPlayerViewController notif_setLoop];
    
    [AudioPlayerViewController notif_setControlsHidden:(playingError != nil)];
    [AudioPlayerViewController notif_setShouldUpdateTime:(playingError == nil)];
}

- (void)skipToPreviousTrack {
    
    if (self.audioPlayer.currentTime > 5) {
        self.audioPlayer.currentTime = 0;
        return;
    }
    
    NSString *currentDir = [_nowPlayingFile stringByDeletingLastPathComponent];
    NSArray *filesOfDir = [[[NSFileManager defaultManager]contentsOfDirectoryAtPath:currentDir error:nil]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSMutableArray *audioFiles = [NSMutableArray array];
    
    for (NSString *filename in filesOfDir) {
        if ([MIMEUtils isAudioFile:filename]) {
            [audioFiles addObject:[currentDir stringByAppendingPathComponent:filename]];
        }
    }

    int nextIndex = [audioFiles indexOfObject:_nowPlayingFile]-1;
    
    if (nextIndex < 0) {
        nextIndex = audioFiles.count-1;
    }
    
    NSString *newFile = audioFiles[nextIndex];
    [self setOpenFile:newFile];
    
    NSError *playingError = nil;

    [self.audioPlayer stop];
    self.audioPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:newFile] error:&playingError];
    self.audioPlayer.delegate = self;
    self.audioPlayer.numberOfLoops = [[NSUserDefaults standardUserDefaults]boolForKey:@"loop"]?-1:0;
    [AudioPlayerViewController notif_setLoop];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            [_audioPlayer prepareToPlay];
            dispatch_sync(dispatch_get_main_queue(), ^{
                @autoreleasepool {
                    [_audioPlayer play];
                    [AudioPlayerViewController notif_setPausePlayTitlePause];
                    self.nowPlayingFile = newFile;
                }
            });
        }
    });
    
    [self loadMetadataForFile:newFile];
    [AudioPlayerViewController notif_setSongTitleText:newFile.lastPathComponent];
    [AudioPlayerViewController notif_setControlsHidden:(playingError != nil)];
    [AudioPlayerViewController notif_setShouldUpdateTime:(playingError == nil)];
}

- (void)skipToNextTrack {

    NSString *currentDir = [_nowPlayingFile stringByDeletingLastPathComponent];
    
    NSArray *filesOfDir = [[[NSFileManager defaultManager]contentsOfDirectoryAtPath:currentDir error:nil]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSMutableArray *audioFiles = [NSMutableArray array];
    
    for (NSString *filename in filesOfDir) {
        if ([MIMEUtils isAudioFile:filename]) {
            [audioFiles addObject:[currentDir stringByAppendingPathComponent:filename]];
        }
    }

    int maxIndex = audioFiles.count-1;
    int nextIndex = [audioFiles indexOfObject:_nowPlayingFile]+1;
    
    if (nextIndex > maxIndex) {
        nextIndex = 0;
    }

    NSString *newFile = audioFiles[nextIndex];
    [self setOpenFile:newFile];
    
    NSError *playingError = nil;
    
    [self.audioPlayer stop];
    self.audioPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:newFile] error:&playingError];
    self.audioPlayer.delegate = self;
    self.audioPlayer.numberOfLoops = [[NSUserDefaults standardUserDefaults]boolForKey:@"loop"]?-1:0;
    [AudioPlayerViewController notif_setLoop];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            [_audioPlayer prepareToPlay];
            dispatch_sync(dispatch_get_main_queue(), ^{
                @autoreleasepool {
                    [_audioPlayer play];
                    [AudioPlayerViewController notif_setPausePlayTitlePause];
                    self.nowPlayingFile = newFile;
                }
            });
        }
    });
    
    [self loadMetadataForFile:newFile];
    
    [AudioPlayerViewController notif_setSongTitleText:[newFile lastPathComponent]];
    [AudioPlayerViewController notif_setControlsHidden:(playingError != nil)];
    [AudioPlayerViewController notif_setShouldUpdateTime:(playingError == nil)];
}

- (void)handleRouteChange:(NSNotification *)notif {
    
    if ([notif.userInfo[AVAudioSessionRouteChangeReasonKey]intValue] == AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {
        AVAudioPlayer *audioPlayer = [kAppDelegate audioPlayer];
        if (audioPlayer.isPlaying) {
            [audioPlayer pause];
            [AudioPlayerViewController notif_setPausePlayTitlePlay];
        }
    }
}

- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player {
    if (_audioPlayer.isPlaying) {
        [_audioPlayer pause];
        [AudioPlayerViewController notif_setPausePlayTitlePlay];
    }
}

- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player withOptions:(NSUInteger)flags {
    NSLog(@"LOL");
    if (!_audioPlayer.isPlaying) {
        [_audioPlayer play];
        [AudioPlayerViewController notif_setPausePlayTitlePause];
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    if (!flag) {
        [AudioPlayerViewController notif_setControlsHidden:YES];
    } else {
        if (self.audioPlayer.numberOfLoops == 0) {
            [self skipToNextTrack];
        } else {
            self.audioPlayer.currentTime = 0;
            [self.audioPlayer play];
            [AudioPlayerViewController notif_setPausePlayTitlePause];
        }
    }
}

- (void)sendFileInEmail:(NSString *)file {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *controller = [[MFMailComposeViewController alloc]initWithCompletionHandler:^(MFMailComposeViewController *controller, MFMailComposeResult result, NSError *error) {
            [controller dismissViewControllerAnimated:YES completion:nil];
        }];
        [controller setSubject:@"Your file"];
        [controller addAttachmentData:[NSData dataWithContentsOfFile:file] mimeType:[MIMEUtils fileMIMEType:file] fileName:[file lastPathComponent]];
        [controller setMessageBody:@"" isHTML:NO];
        [[UIViewController topViewController]presentViewController:controller animated:YES completion:nil];
    } else {
        [UIAlertView showAlertWithTitle:@"Mail Unavailable" andMessage:@"In order to email files, you must set up an mail account in Settings."];
    }
}

- (void)sendStringAsSMS:(NSString *)string fromViewController:(UIViewController *)vc {
    if ([MFMessageComposeViewController canSendText]) {
        MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc]initWithCompletionHandler:^(MFMessageComposeViewController *controller, MessageComposeResult result) {
            [controller dismissViewControllerAnimated:YES completion:nil];
        }];
        [controller setBody:string];
        [vc presentViewController:controller animated:YES completion:nil];
    } else {
        [UIAlertView showAlertWithTitle:@"SMS unavailable" andMessage:@"Please double check if you can send SMS messsages or iMessages."];
    }
}

- (void)printFile:(NSString *)file fromView:(UIView *)view {
    UIPrintInteractionController *pic = [UIPrintInteractionController sharedPrintController];
    UIPrintInfo *printInfo = [UIPrintInfo printInfo];
    printInfo.outputType = UIPrintInfoOutputGeneral;
    printInfo.jobName = [file lastPathComponent];
    printInfo.duplex = UIPrintInfoDuplexLongEdge;
    pic.printInfo = printInfo;
    pic.showsPageRange = YES;
    pic.printingItem = [NSURL fileURLWithPath:file];
    
    void (^completionHandler)(UIPrintInteractionController *, BOOL, NSError *) = ^(UIPrintInteractionController *pic, BOOL completed, NSError *error) {
        if (error) {
            [UIAlertView showAlertWithTitle:[NSString stringWithFormat:@"Error %u",error.code] andMessage:error.localizedDescription];
        }
    };
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [pic presentFromRect:CGRectMake(716, 967, 44, 37) inView:view animated:YES completionHandler:completionHandler];
    } else {
        [pic presentAnimated:YES completionHandler:completionHandler];
    }
}

- (void)downloadFileUsingSFTP:(NSURL *)url withUsername:(NSString *)username andPassword:(NSString *)password {
    SFTPDownload *download = [SFTPDownload downloadWithURL:url username:username andPassword:password];
    [[TaskController sharedController]addTask:download];
}

- (void)downloadFile:(NSString *)stouPrelim {
    
    if (stouPrelim.length == 0) {
        return;
    }
    
    NSURL *url = [NSURL URLWithString:stouPrelim];
    
    if (url.scheme.length == 0) {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@",stouPrelim]];
    }
    
    if (!url) {
        [UIAlertView showAlertWithTitle:@"Invalid URL" andMessage:@"The URL you have provided is somehow bogus."];
        return;
    }
    
    [[TaskController sharedController]addTask:[url.scheme isEqualToString:@"ftp"]?[FTPDownload downloadWithURL:url]:[HTTPDownload downloadWithURL:url]];
}

- (BOOL)isInForground {
    return [[UIApplication sharedApplication]applicationState] != UIApplicationStateBackground;
}

// Dropbox Upload
- (void)uploadLocalFileToDropbox:(NSString *)localPath {
    DropboxUpload *task = [DropboxUpload uploadWithFile:localPath];
    [[TaskController sharedController]addTask:task];
}

- (void)sessionDidReceiveAuthorizationFailure:(DBSession *)session userId:(NSString *)userId {
    [UIAlertView showAlertWithTitle:@"Dropbox Authentication Failed" andMessage:@"Please try reauthenticating in Settings"];
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event {
    if (event.type == UIEventTypeRemoteControl) {
        if (event.subtype == UIEventSubtypeRemoteControlPlay) {
            [self.audioPlayer play];
            [AudioPlayerViewController notif_setPausePlayTitlePause];
        } else if (event.subtype == UIEventSubtypeRemoteControlPause) {
            [self.audioPlayer pause];
            [AudioPlayerViewController notif_setPausePlayTitlePlay];
        } else if (event.subtype == UIEventSubtypeRemoteControlTogglePlayPause) {
            [self togglePlayPause];
        } else if (event.subtype == UIEventSubtypeRemoteControlNextTrack) {
            [self skipToNextTrack];
        } else if (event.subtype == UIEventSubtypeRemoteControlPreviousTrack) {
            [self skipToPreviousTrack];
        }
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // Trust me
    [FilesystemMonitor sharedMonitor];
    [BGProcFactory sharedFactory];
    [TaskController sharedController];
    [BluetoothManager sharedManager];
    [NetworkActivityController sharedController];
    
    [[BluetoothManager sharedManager]setStartedBlock:^{
        if (![[BluetoothManager sharedManager]isSender]) {
            BluetoothTask *task = [BluetoothTask receiverTaskWithFilename:[[BluetoothManager sharedManager]getFilename]];
            [[TaskController sharedController]addTask:task];
        }
    }];
    
    [[AVAudioSession sharedInstance]setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[UIApplication sharedApplication]beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(handleRouteChange:) name:AVAudioSessionRouteChangeNotification object:[AVAudioSession sharedInstance]];
    //AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, audioRouteChangeListenerCallback, nil);
    
    DBSession *session = [[DBSession alloc]initWithAppKey:@"ybpwmfq2z1jmaxi" appSecret:@"ua6hjow7hxx0y3a" root:kDBRootDropbox];
	session.delegate = self;
	[DBSession setSharedSession:session];
    
    self.window = [[UIWindow alloc]initWithFrame:[[UIScreen mainScreen]bounds]];
    self.window.opaque = YES;
    self.viewController = [MyFilesViewController viewController];
    _window.rootViewController = self.viewController;
    _window.backgroundColor = [UIColor whiteColor];
    [_window makeKeyAndVisible];
    
    [Appirater setAppId:@"469762999"];
    [Appirater setDaysUntilPrompt:5];
    [Appirater setUsesUntilPrompt:10];
    [Appirater setSignificantEventsUntilPrompt:-1];
    [Appirater setTimeBeforeReminding:2];
    [Appirater appLaunched:YES];
    
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [[BluetoothManager sharedManager]prepareForBackground];
}

- (void)applicationWillEnterForeground:(UIApplication *)application  {
    [[BluetoothManager sharedManager]prepareForForeground];
    [Appirater appEnteredForeground:YES];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [[FilesystemMonitor sharedMonitor]invalidate];
    [[BGProcFactory sharedFactory]endAllTasks];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    [[NSURLCache sharedURLCache]removeAllCachedResponses];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    if (url.absoluteString.length == 0) {
        return NO;
    }
    
    if ([[DBSession sharedSession]handleOpenURL:url]) {
        [[NSNotificationCenter defaultCenter]postNotificationName:[[DBSession sharedSession]isLinked]?@"db_auth_success":@"db_auth_failure" object:nil];
        return YES;
    }
    
    if (url.isFileURL) {
        NSString *inboxDir = [kDocsDir stringByAppendingPathComponent:@"Inbox"];
        NSArray *filesInIndexDir = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:inboxDir error:nil];
        
        for (NSString *filename in filesInIndexDir) {
            NSString *newLocation = getNonConflictingFilePathForPath([kDocsDir stringByAppendingPathComponent:filename]);
            NSString *oldLocation = [inboxDir stringByAppendingPathComponent:filename];
            [[NSFileManager defaultManager]moveItemAtPath:oldLocation toPath:newLocation error:nil];
        }

        // Attemp to remove it on the off chance that it actually works
        [[NSFileManager defaultManager]removeItemAtPath:inboxDir error:nil];
        
        if (filesInIndexDir.count > 0) {
            NSString *file = [kDocsDir stringByAppendingPathComponent:filesInIndexDir[0]];
            self.openFile = file;

            BOOL isHTML = [MIMEUtils isHTMLFile:file];
            
            if ([MIMEUtils isAudioFile:file]) {
                [[UIViewController topViewController]presentViewController:[AudioPlayerViewController viewController] animated:YES completion:nil];
            } else if ([MIMEUtils isImageFile:file]) {
                [[UIViewController topViewController]presentViewController:[PictureViewController viewController] animated:YES completion:nil];
            } else if ([MIMEUtils isTextFile:file] && !isHTML) {
                [[UIViewController topViewController]presentViewController:[TextEditorViewController viewController] animated:YES completion:nil];
            } else if ([MIMEUtils isVideoFile:file]) {
                [[UIViewController topViewController]presentViewController:[MoviePlayerViewController viewController] animated:YES completion:nil];
            } else if ([MIMEUtils isDocumentFile:file] || isHTML) {
                [[UIViewController topViewController]presentViewController:[DocumentViewController viewController] animated:YES completion:nil];
            }
        }

    } else {
        NSString *URLString = nil;
        if ([url.absoluteString hasPrefix:@"swiftload://"]) {
            URLString = [url.absoluteString stringByReplacingOccurrencesOfString:@"swiftload://" withString:@"http://"];
        } else if ([url.absoluteString hasPrefix:@"swift://"]) {
            URLString = [url.absoluteString stringByReplacingOccurrencesOfString:@"swift://" withString:@"http://"];
        }
        
        if (URLString.length > 0) {
            [self downloadFile:URLString];
        }
    }

    return YES;
}

@end