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

void fireNotification(NSString *filename) {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
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

void audioRouteChangeListenerCallback(void *inUserData, AudioSessionPropertyID inPropertyID, UInt32 inPropertyValueSize, const void *inPropertyValue) {
    
    if (inPropertyID == kAudioSessionProperty_AudioRouteChange) {
        CFNumberRef routeChangeReasonRef = CFDictionaryGetValue((CFDictionaryRef)inPropertyValue, CFSTR(kAudioSession_AudioRouteChangeKey_Reason));
        
        SInt32 routeChangeReason;
        CFNumberGetValue(routeChangeReasonRef, kCFNumberSInt32Type, &routeChangeReason);
        
        if (routeChangeReason == kAudioSessionRouteChangeReason_OldDeviceUnavailable) {
            if ([[kAppDelegate audioPlayer]isPlaying]) {
                [[kAppDelegate audioPlayer]pause];
            }
        }
    }
}

@implementation AppDelegate

//
// Audio Player
//

- (void)artworksForFileAtPath:(NSString *)path block:(void(^)(NSArray *artworkImages))block {
    
    if (!block) {
        return;
    }
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:path] options:nil];
    NSArray *keys = [NSArray arrayWithObjects:@"commonMetadata", nil];
    [asset loadValuesAsynchronouslyForKeys:keys completionHandler:^{
        NSArray *artworks = [AVMetadataItem metadataItemsFromArray:asset.commonMetadata withKey:AVMetadataCommonKeyArtwork keySpace:AVMetadataKeySpaceCommon];
        
        NSMutableArray *artworkImages = [NSMutableArray array];
        for (AVMetadataItem *item in artworks) {
            NSString *keySpace = item.keySpace;
            
            UIImage *image = nil;
            
            if ([keySpace isEqualToString:AVMetadataKeySpaceID3]) {
                image = [UIImage imageWithData:[(NSDictionary *)item.value objectForKey:@"data"]];
            } else if ([keySpace isEqualToString:AVMetadataKeySpaceiTunes]) {
                image = [UIImage imageWithData:(NSData *)item.value];
            }
            
            if (image != nil) {
                [artworkImages addObject:image];
            }
        }
        
        block(artworkImages);
    }];
}

- (void)showArtworkForFile:(NSString *)file {
    [self artworksForFileAtPath:file block:^(NSArray *artworkImages) {
        if (artworkImages.count > 0) {
            UIImage *image = [artworkImages firstObjectCommonWithArray:artworkImages];
            if (image != nil) {
                MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
                MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc]initWithImage:image];
                NSMutableDictionary *dict = [center.nowPlayingInfo mutableCopy];
                [dict setObject:artwork forKey:MPMediaItemPropertyArtwork];
                center.nowPlayingInfo = dict;
            }
        }
    }];
}

- (void)showMetadataInLockscreenWithArtist:(NSString *)artist title:(NSString *)title album:(NSString *)album {
    if ([artist isEqualToString:@"---"]) {
        artist = nil;
    }
    
    if ([title isEqualToString:@"---"]) {
        title = nil;
    }
    
    if ([album isEqualToString:@"---"]) {
        album = nil;
    }
    
    NSDictionary *songInfo = [NSDictionary dictionaryWithObjectsAndKeys:artist, MPMediaItemPropertyArtist, title, MPMediaItemPropertyTitle, album, MPMediaItemPropertyAlbumTitle, nil];
    [[MPNowPlayingInfoCenter defaultCenter]setNowPlayingInfo:songInfo];
}

- (void)togglePlayPause {
    if (!self.audioPlayer.isPlaying) {
        [self.audioPlayer play];
        self.nowPlayingFile = [self.openFile copy];
        [AudioPlayerViewController notif_setPausePlayTitlePause];
        [AudioPlayerViewController notif_setShouldUpdateTime:YES];
    } else {
        [self.audioPlayer pause];
        [AudioPlayerViewController notif_setPausePlayTitlePlay];
        [AudioPlayerViewController notif_setShouldUpdateTime:NO];
    }
}

- (void)skipToPreviousTrack {
    
    if (self.audioPlayer.currentTime > 5) {
        self.audioPlayer.currentTime = 0;
        return;
    }
    
    NSString *currentDir = [self.nowPlayingFile stringByDeletingLastPathComponent];
    NSArray *filesOfDir = [[[NSFileManager defaultManager]contentsOfDirectoryAtPath:currentDir error:nil]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSMutableArray *audioFiles = [NSMutableArray array];
    
    for (NSString *object in filesOfDir) {
        NSString *newObject = [currentDir stringByAppendingPathComponent:object];
        if ([MIMEUtils isAudioFile:newObject]) {
            [audioFiles addObject:newObject];
        }
    }

    int nextIndex = [audioFiles indexOfObject:self.nowPlayingFile]-1;
    
    if (nextIndex < 0) {
        [AudioPlayerViewController notif_setPrevTrackHidden:YES];
        return;
    }
    
    if (nextIndex == 0) {
        [AudioPlayerViewController notif_setPrevTrackHidden:YES];
    }
    
    [AudioPlayerViewController notif_setNxtTrackHidden:NO];
    
    NSString *newFile = [audioFiles objectAtIndex:nextIndex];
    [self setOpenFile:newFile];
    
    NSError *playingError = nil;
    
    [AudioPlayerViewController notif_setSongTitleText:[newFile lastPathComponent]];
    
    NSArray *iA = [metadataRetriever getMetadataForFile:newFile];
    NSString *artist = [iA objectAtIndex:0];
    NSString *title = [iA objectAtIndex:1];
    NSString *album = [iA objectAtIndex:2];
    NSString *metadata = [NSString stringWithFormat:@"%@\n%@\n%@",artist,title,album];
    [AudioPlayerViewController notif_setInfoFieldText:metadata];
    
    if ([artist isEqualToString:@"---"] && [title isEqualToString:@"---"] && [album isEqualToString:@"---"]) {
        [self showMetadataInLockscreenWithArtist:@"" title:[newFile lastPathComponent] album:@""];
    } else {
        [self showMetadataInLockscreenWithArtist:artist title:title album:album];
    }
    
    [self showArtworkForFile:newFile];
    
    NSString *savedLoop = [kLibDir stringByAppendingPathComponent:@"loop.txt"];
    NSString *loopContents = [NSString stringWithContentsOfFile:savedLoop encoding:NSUTF8StringEncoding error:nil];
    
    [self.audioPlayer stop];
    self.audioPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:newFile] error:&playingError];
    self.audioPlayer.delegate = self;
    self.audioPlayer.numberOfLoops = [loopContents isEqualToString:@"loop"]?-1:0;
    
    [AudioPlayerViewController notif_setLoop];
    
    [self.audioPlayer play];
    
    [self setNowPlayingFile:newFile];
    [AudioPlayerViewController notif_setControlsHidden:(playingError != nil)];
    [AudioPlayerViewController notif_setShouldUpdateTime:(playingError == nil)];
}

- (void)skipToNextTrack {

    NSString *currentDir = [self.nowPlayingFile stringByDeletingLastPathComponent];
    
    NSArray *filesOfDir = [[[NSFileManager defaultManager]contentsOfDirectoryAtPath:currentDir error:nil]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSMutableArray *audioFiles = [NSMutableArray array];
    
    for (NSString *object in filesOfDir) {
        NSString *newObject = [currentDir stringByAppendingPathComponent:object];
        if ([MIMEUtils isAudioFile:newObject]) {
            [audioFiles addObject:newObject];
        }
    }

    int maxIndex = audioFiles.count-1;
    int nextIndex = [audioFiles indexOfObject:self.nowPlayingFile]+1;
    
    if (nextIndex > maxIndex) {
        [AudioPlayerViewController notif_setNxtTrackHidden:YES];
        return;
    }
    
    if (nextIndex == maxIndex) {
        [AudioPlayerViewController notif_setNxtTrackHidden:YES];
    }
    
    [AudioPlayerViewController notif_setPrevTrackHidden:NO];
    
    NSString *newFile = [audioFiles objectAtIndex:nextIndex];
    [self setOpenFile:newFile];
    
    NSError *playingError = nil;
    
    [AudioPlayerViewController notif_setSongTitleText:[newFile lastPathComponent]];
    
    NSArray *iA = [metadataRetriever getMetadataForFile:newFile];
    NSString *artist = [iA objectAtIndex:0];
    NSString *title = [iA objectAtIndex:1];
    NSString *album = [iA objectAtIndex:2];
    NSString *metadata = [NSString stringWithFormat:@"%@\n%@\n%@",artist,title,album];

    [AudioPlayerViewController notif_setInfoFieldText:metadata];
    
    NSString *savedLoop = [kLibDir stringByAppendingPathComponent:@"loop.txt"];
    NSString *loopContents = [NSString stringWithContentsOfFile:savedLoop encoding:NSUTF8StringEncoding error:nil];
    
    if ([artist isEqualToString:@"---"] && [title isEqualToString:@"---"] && [album isEqualToString:@"---"]) {
        [self showMetadataInLockscreenWithArtist:@"" title:[newFile lastPathComponent] album:@""];
    } else {
        [self showMetadataInLockscreenWithArtist:artist title:title album:album];
    }
    
    [self showArtworkForFile:newFile];
    
    [self.audioPlayer stop];
    self.audioPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:newFile] error:&playingError];
    self.audioPlayer.delegate = self;
    self.audioPlayer.numberOfLoops = [loopContents isEqualToString:@"loop"]?-1:0;
    [AudioPlayerViewController notif_setLoop];
    [self.audioPlayer play];
    
    [self setNowPlayingFile:newFile];
    [AudioPlayerViewController notif_setControlsHidden:(playingError != nil)];
    [AudioPlayerViewController notif_setShouldUpdateTime:(playingError == nil)];
}

- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player {
    if (self.audioPlayer.isPlaying) {
        [self.audioPlayer pause];
    }
}

- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player {
    if (!self.audioPlayer.isPlaying) {
        [self.audioPlayer play];
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    if (self.audioPlayer.numberOfLoops == 0) {
        [self skipToNextTrack];
    } else {
        self.audioPlayer.currentTime = 0;
        [self.audioPlayer play];
    }
}

- (void)sendFileInEmail:(NSString *)file fromViewController:(UIViewController *)vc {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *controller = [[MFMailComposeViewController alloc]initWithCompletionHandler:^(MFMailComposeViewController *controller, MFMailComposeResult result, NSError *error) {
            [vc dismissModalViewControllerAnimated:YES];
        }];
        [controller setSubject:@"Your file"];
        [controller addAttachmentData:[NSData dataWithContentsOfFile:file] mimeType:[MIMEUtils fileMIMEType:file] fileName:[file lastPathComponent]];
        [controller setMessageBody:@"" isHTML:NO];
        [vc presentModalViewController:controller animated:YES];
    } else {
        [TransparentAlert showAlertWithTitle:@"Mail Unavailable" andMessage:@"In order to email files, you must set up an mail account in Settings."];
    }
}

- (void)sendStringAsSMS:(NSString *)string fromViewController:(UIViewController *)vc {
    if ([MFMessageComposeViewController canSendText]) {
        MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc]initWithCompletionHandler:^(MFMessageComposeViewController *controller, MessageComposeResult result) {
            [vc dismissModalViewControllerAnimated:YES];
        }];
        [controller setBody:string];
        [vc presentModalViewController:controller animated:YES];
    } else {
        [TransparentAlert showAlertWithTitle:@"SMS unavailable" andMessage:@"Please double check if you can send SMS messsages or iMessages."];
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
            [TransparentAlert showAlertWithTitle:[NSString stringWithFormat:@"Error %u",error.code] andMessage:error.localizedDescription];
        }
    };
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [pic presentFromRect:CGRectMake(716, 967, 44, 37) inView:view animated:YES completionHandler:completionHandler];
    } else {
        [pic presentAnimated:YES completionHandler:completionHandler];
    }
}

- (void)prepareFileForBTSending:(NSString *)file {
    [[BluetoothManager sharedManager]loadFile:file];
    [[BluetoothManager sharedManager]searchForPeers];
}

- (void)downloadFileUsingSFTP:(NSURL *)url withUsername:(NSString *)username andPassword:(NSString *)password {
    SFTPDownload *download = [SFTPDownload downloadWithURL:url username:username andPassword:password];
    [[DownloadController sharedController]addDownload:download];
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
        [TransparentAlert showAlertWithTitle:@"Invalid URL" andMessage:@"The URL you have provided is somehow bogus."];
        return;
    }
    
    if ([url.scheme isEqualToString:@"ftp"]) {
        FTPDownload *download = [FTPDownload downloadWithURL:url];
        [[DownloadController sharedController]addDownload:download];
        return;
    }
    
    HTTPDownload *download = [HTTPDownload downloadWithURL:url];
    [[DownloadController sharedController]addDownload:download];
}

- (BOOL)isInForground {
    return [[UIApplication sharedApplication]applicationState] != UIApplicationStateBackground;
}

// Dropbox Upload
- (void)uploadLocalFile:(NSString *)localPath {
    [self showHUDWithTitle:@"Preparing"];
    [self setVisibleHudMode:MBProgressHUDModeIndeterminate];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [DroppinBadassBlocks loadMetadata:@"/" withCompletionBlock:^(DBMetadata *metadata, NSError *error) {
        
        if (error) {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            [self hideHUD];
            [TransparentAlert showAlertWithTitle:@"Failure Uploading" andMessage:@"Swift could not connect to Dropbox."];
        } else {
            NSString *rev = nil;
            
            if (metadata.isDirectory) {
                for (DBMetadata *file in metadata.contents) {
                    if (file.isDirectory) {
                        continue;
                    }
                    
                    if ([file.filename isEqualToString:[self.openFile lastPathComponent]]) {
                        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
                        rev = file.rev;
                        break;
                    }
                }
                
                [self setVisibleHudMode:MBProgressHUDModeDeterminate];
                [self setTitleOfVisibleHUD:@"Uploading..."];
                [DroppinBadassBlocks uploadFile:[self.openFile lastPathComponent] toPath:@"/" withParentRev:rev fromPath:localPath withBlock:^(NSString *destPath, NSString *srcPath, DBMetadata *metadata, NSError *error) {
                    
                    if (error) {
                        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                        [self hideHUD];
                        [TransparentAlert showAlertWithTitle:@"Failure Uploading" andMessage:[NSString stringWithFormat:@"The file you tried to upload failed because: %@",error.localizedDescription]];
                    } else {
                        [DroppinBadassBlocks loadSharableLinkForFile:metadata.path andCompletionBlock:^(NSString *link, NSString *path, NSError *error) {
                            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                            [self hideHUD];
                            
                            if (error) {
                                [TransparentAlert showAlertWithTitle:[NSString stringWithFormat:@"Error %d",error.code] andMessage:@"Upload succeeded, but there was a problem generating a sharable link."];
                            } else {
                                [[[TransparentAlert alloc]initWithTitle:[NSString stringWithFormat:@"Link For:\n%@",[path lastPathComponent]] message:link completionBlock:^(NSUInteger buttonIndex, UIAlertView *alertView) {
                                    if (buttonIndex == 1) {
                                        [[UIPasteboard generalPasteboard]setString:alertView.message];
                                    }
                                } cancelButtonTitle:@"OK" otherButtonTitles:@"Copy", nil]show];
                            }
                        }];
                    }
                    
                } andProgressBlock:^(CGFloat progress, NSString *destPath, NSString *scrPath) {
                    [self setProgressOfVisibleHUD:progress];
                }];
            }
        }
    }];
}

- (void)sessionDidReceiveAuthorizationFailure:(DBSession *)session userId:(NSString *)userId {
    [TransparentAlert showAlertWithTitle:@"Dropbox Authentication Failed" andMessage:@"Please try reauthenticating in Settings"];
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
    [DownloadController sharedController];
    [BluetoothManager sharedManager];
    
    [[AVAudioSession sharedInstance]setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[UIApplication sharedApplication]beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
    AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, audioRouteChangeListenerCallback, nil);
    
    DBSession *session = [[DBSession alloc]initWithAppKey:@"ybpwmfq2z1jmaxi" appSecret:@"ua6hjow7hxx0y3a" root:kDBRootDropbox];
	session.delegate = self;
	[DBSession setSharedSession:session];
    
    [[BluetoothManager sharedManager]setStartedBlock:^{
        [[BGProcFactory sharedFactory]startProcForKey:@"bluetooth_ft" andExpirationHandler:^{
            [[BluetoothManager sharedManager]cancel];
        }];
        
        [self showHUDWithTitle:[[BluetoothManager sharedManager]isSender]?@"Sending":@"Receiving"];
        [self setSecondaryTitleOfVisibleHUD:[[BluetoothManager sharedManager]getFilename]];
        [self setVisibleHudMode:MBProgressHUDModeDeterminate];
    }];
    [[BluetoothManager sharedManager]setProgressBlock:^(float progress) {
        [self setProgressOfVisibleHUD:progress];
    }];
    [[BluetoothManager sharedManager]setCompletionBlock:^(NSError *error, BOOL cancelled) {
        [[BGProcFactory sharedFactory]endProcForKey:@"bluetooth_ft"];
        [self hideHUD];
        if (!cancelled) {
            if (!error) {
                [TransparentAlert showAlertWithTitle:@"Success" andMessage:[NSString stringWithFormat:@"\"%@\" has been successfully %@.",[[BluetoothManager sharedManager]getFilename],[[BluetoothManager sharedManager]isSender]?@"sent":@"received"]];
            } else {
                [TransparentAlert showAlertWithTitle:@"Bluetooth Error" andMessage:error.domain];
            }
        }
    }];
    
    self.window = [[UIWindow alloc]initWithFrame:[[UIScreen mainScreen]bounds]];
    self.window.opaque = YES;
    self.viewController = [MyFilesViewController viewController];
    _window.rootViewController = self.viewController;
    _window.backgroundColor = [UIColor colorWithWhite:9.0f/10.0f alpha:1.0f];
    [_window makeKeyAndVisible];

    UIImage *bbiImage = [[UIImage imageNamed:@"toolbar_icon"]resizableImageWithCapInsets:UIEdgeInsetsMake(0, 4, 0, 4)];
    [[UIBarButtonItem appearance]setBackgroundImage:bbiImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];

    UIImage *navBarImage = [[UIImage imageNamed:@"statusbar"]resizableImageWithCapInsets:UIEdgeInsetsMake(0, 150, 0, 150)];
    [[UINavigationBar appearance]setBackgroundImage:navBarImage forBarMetrics:UIBarMetricsDefault];
    [[UIToolbar appearance]setBackgroundImage:navBarImage forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance]setTitleTextAttributes:@{ UITextAttributeTextColor: [UIColor whiteColor] }];
    [[UIBarButtonItem appearance]setTitleTextAttributes:@{ UITextAttributeTextColor: [UIColor whiteColor], UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetMake(0, 0)] } forState:UIControlStateNormal];
    
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
    
        [[NSFileManager defaultManager]removeItemAtPath:inboxDir error:nil];
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        fireNotification(url.absoluteString.lastPathComponent);
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

//
// MBProgressHUD methods
//

- (int)getTagOfVisibleHUD {
    return [MBProgressHUD HUDForView:self.window].tag;
}

- (void)setTagOfVisibleHUD:(int)tag {
    [MBProgressHUD HUDForView:self.window].tag = tag;
}

- (MBProgressHUD *)getVisibleHUD {
    return [MBProgressHUD HUDForView:self.window];
}

- (void)hideVisibleHudAfterDelay:(float)delay {
    [[MBProgressHUD HUDForView:self.window]hide:YES afterDelay:delay];
}

- (void)setVisibleHudCustomView:(UIView *)view {
    [[MBProgressHUD HUDForView:self.window]setMode:MBProgressHUDModeCustomView];
    [[MBProgressHUD HUDForView:self.window]setCustomView:view];
}

- (void)setVisibleHudMode:(MBProgressHUDMode)mode {
    [[MBProgressHUD HUDForView:self.window]setMode:mode];
}

- (void)showHUDWithTitle:(NSString *)title {
    [self hideHUD];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.window animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = title;
}

- (void)hideHUD {
    for (UIView *view in self.window.subviews) {
        if ([view isKindOfClass:[MBProgressHUD class]]) {
            [view removeFromSuperview];
        }
    }
    [MBProgressHUD hideAllHUDsForView:self.window animated:YES];
}

- (void)setSecondaryTitleOfVisibleHUD:(NSString *)newTitle {
    [[MBProgressHUD HUDForView:self.window]setDetailsLabelText:newTitle];
}

- (void)setTitleOfVisibleHUD:(NSString *)newTitle {
    [[MBProgressHUD HUDForView:self.window]setLabelText:newTitle];
}

- (void)setProgressOfVisibleHUD:(float)progress {
    MBProgressHUD *hud = [MBProgressHUD HUDForView:self.window];
    
    if (hud.mode == MBProgressHUDModeDeterminate) {
        hud.progress = progress;
    }
}

- (void)showSelfHidingHudWithTitle:(NSString *)title {
    [self hideHUD];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.window animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.labelText = title;
    [hud hide:YES afterDelay:1.5];
}

@end