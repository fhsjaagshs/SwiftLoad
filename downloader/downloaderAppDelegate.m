//
//  downloaderAppDelegate.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 8/11/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import "downloaderAppDelegate.h"

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
    [notification release];
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

@implementation downloaderAppDelegate

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
                [artwork release];
                center.nowPlayingInfo = dict;
                [dict release];
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
        self.nowPlayingFile = [[self.openFile copy]autorelease];
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
    self.audioPlayer = [[[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:newFile] error:&playingError]autorelease];
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
    self.audioPlayer = [[[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:newFile] error:&playingError]autorelease];
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

//
// Emailing
//

- (void)sendFileInEmail:(NSString *)file fromViewController:(UIViewController *)vc {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *controller = [[MFMailComposeViewController alloc]initWithCompletionHandler:^(MFMailComposeViewController *controller, MFMailComposeResult result, NSError *error) {
            [vc dismissModalViewControllerAnimated:YES];
        }];
        [controller setSubject:@"Your file"];
        [controller addAttachmentData:[NSData dataWithContentsOfFile:file] mimeType:[MIMEUtils fileMIMEType:file] fileName:[file lastPathComponent]];
        [controller setMessageBody:@"" isHTML:NO];
        [vc presentModalViewController:controller animated:YES];
        [controller release];
    } else {
        [TransparentAlert showAlertWithTitle:@"Mail Unavailable" andMessage:@"In order to email files, you must set up an mail account in Settings."];
    }
}

//
// Texting
//

- (void)sendStringAsSMS:(NSString *)string fromViewController:(UIViewController *)vc {
    if ([MFMessageComposeViewController canSendText]) {
        MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc]initWithCompletionHandler:^(MFMessageComposeViewController *controller, MessageComposeResult result) {
            [vc dismissModalViewControllerAnimated:YES];
        }];
        [controller setBody:string];
        [vc presentModalViewController:controller animated:YES];
        [controller release];
    } else {
        [TransparentAlert showAlertWithTitle:@"SMS unavailable" andMessage:@"Please double check if you can send SMS messsages or iMessages."];
    }
}

//
// Printing
//

- (void)printFile:(NSString *)file fromView:(UIView *)view {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSAutoreleasePool *poolTwo = [[NSAutoreleasePool alloc]init];
            
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
                    [TransparentAlert showAlertWithTitle:[NSString stringWithFormat:@"Error %u",error.code] andMessage:error.domain];
                }
            };
            
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                [pic presentFromRect:CGRectMake(716, 967, 44, 37) inView:view animated:YES completionHandler:completionHandler];
            } else {
                [pic presentAnimated:YES completionHandler:completionHandler];
            }
            
            [poolTwo release];
        });
        [pool release];
    });
}

//
// AppDelegate Downloading
//

/*- (void)showFinishedAlertForFilename:(NSString *)fileName {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if (fileName.length > 14) {
        fileName = [[fileName substringToIndex:11]stringByAppendingString:@"..."];
    }

    UILocalNotification *notification = [[UILocalNotification alloc]init];
    notification.fireDate = [NSDate date];
    notification.alertBody = [NSString stringWithFormat:@"Finished downloading: %@",fileName];
    notification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication]presentLocalNotificationNow:notification];
    [notification release];
 
    [[HUDProgressView progressViewWithTag:0]redrawGreen];
    [[HUDProgressView progressViewWithTag:0]hideAfterDelay:1.5f];
}

- (void)showExistsAlertForFilename:(NSString *)fnZ {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if (fnZ.length > 14) {
        fnZ = [[fnZ substringToIndex:11]stringByAppendingString:@"..."];
    }
    
    UILocalNotification *notification = [[UILocalNotification alloc]init];
    notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
    notification.alertBody = [NSString stringWithFormat:@"Already Exists: %@",fnZ];
    notification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication]presentLocalNotificationNow:notification];
    [notification release];

    if ([self isInForground]) {
        TransparentAlert *av = [[TransparentAlert alloc]initWithTitle:@"File Exists" message:[NSString stringWithFormat:@"\"%@\" already exists.",fnZ] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [av show];
        [av release];
    }
}*/

/*- (void)showFailedAlertForFilename:(NSString *)fileName {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if (fileName.length > 14) {
        fileName = [[fileName substringToIndex:11]stringByAppendingString:@"..."];
    }
    
    UILocalNotification *notification = [[UILocalNotification alloc]init];
    notification.fireDate = [NSDate date];
    notification.alertBody = [NSString stringWithFormat:@"Download Failed: %@",fileName];
    notification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication]presentLocalNotificationNow:notification];
    [notification release];
    
    if ([self isInForground]) {
        NSString *message = [NSString stringWithFormat:@"SwiftLoad failed to download \"%@\". Please try again later.",fileName];
        TransparentAlert *av = [[TransparentAlert alloc]initWithTitle:@"Oops..." message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [av show];
        [av release];
    }
}*/

- (void)downloadFromAppDelegate:(NSString *)stouPrelim {
    
    NSURL *url = [NSURL URLWithString:stouPrelim];
    
    if (!url) {
        [TransparentAlert showAlertWithTitle:@"Invalid URL" andMessage:@"The URL you have provided is somehow bogus."];
        return;
    }
    
    if (![stouPrelim hasPrefix:@"http"]) {
        
        if ([stouPrelim hasPrefix:@"sftp"] || [stouPrelim hasPrefix:@"rsync"] || [stouPrelim hasPrefix:@"afp"]) {
            [TransparentAlert showAlertWithTitle:@"Invalid URL" andMessage:@"The URL you have provided is not HTTP or FTP."];
            return;
        }
        
        stouPrelim = [NSString stringWithFormat:@"http://%@",stouPrelim];
    }
    
    HTTPDownload *download = [HTTPDownload downloadWithURL:url];
    download.fileName = [url.absoluteString.lastPathComponent stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [[Downloads sharedDownloads]addDownload:download];
}

- (BOOL)isInForground {
    return ([[UIApplication sharedApplication]applicationState] == UIApplicationStateActive || [[UIApplication sharedApplication]applicationState] == UIApplicationStateInactive);
}

//
// Dropbox Upload
// 

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
                        NSLog(@"Here: %@",error);
                        [TransparentAlert showAlertWithTitle:@"Failure Uploading" andMessage:[NSString stringWithFormat:@"The file you tried to upload failed because: %@",error.localizedDescription]];
                    } else {
                        [DroppinBadassBlocks loadSharableLinkForFile:metadata.path andCompletionBlock:^(NSString *link, NSString *path, NSError *error) {
                            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                            [self hideHUD];
                            
                            if (error) {
                                [TransparentAlert showAlertWithTitle:[NSString stringWithFormat:@"Error %d",error.code] andMessage:@"Upload succeeded, but there was a problem generating a sharable link."];
                            } else {
                                [[[[TransparentAlert alloc]initWithTitle:[NSString stringWithFormat:@"Link For:\n%@",[path lastPathComponent]] message:link completionBlock:^(NSUInteger buttonIndex, UIAlertView *alertView) {
                                    if (buttonIndex == 1) {
                                        [[UIPasteboard generalPasteboard]setString:alertView.message];
                                    }
                                } cancelButtonTitle:@"OK" otherButtonTitles:@"Copy", nil]autorelease]show];
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
    [Downloads sharedDownloads];
    [DownloadController sharedController];
    [BGProcFactory sharedFactory];
    
    [[AVAudioSession sharedInstance]setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[UIApplication sharedApplication]beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
    AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, audioRouteChangeListenerCallback, nil);
    
    DBSession *session = [[DBSession alloc]initWithAppKey:@"ybpwmfq2z1jmaxi" appSecret:@"ua6hjow7hxx0y3a" root:kDBRootDropbox];
	session.delegate = self;
	[DBSession setSharedSession:session];
    [session release];
    
    if (_sessionController.session && !_isReciever) {
        [self killSession];
        [self startSession];
    } else if (!_sessionController.session) {
        [self startSession];
    }
    
    self.window = [[[UIWindow alloc]initWithFrame:[[UIScreen mainScreen]bounds]]autorelease];
    self.viewController = [MyFilesViewController viewController];
    _window.rootViewController = self.viewController;
    //_window.backgroundColor = [UIColor colorWithRed:240.0f/255.0f green:248.0f/255.0f blue:1.0f alpha:1.0f];
    _window.backgroundColor = [UIColor colorWithWhite:9.0f/10.0f alpha:1.0f];
    [_window makeKeyAndVisible];

    UIImage *bbiImage = [[UIImage imageNamed:@"toolbar_icon"]resizableImageWithCapInsets:UIEdgeInsetsMake(0, 4, 0, 4)];
    [[UIBarButtonItem appearance]setBackgroundImage:bbiImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];

    UIImage *navBarImage = [[UIImage imageNamed:@"statusbar"]resizableImageWithCapInsets:UIEdgeInsetsMake(0, 150, 0, 150)];
    [[UINavigationBar appearance]setBackgroundImage:navBarImage forBarMetrics:UIBarMetricsDefault];
    [[UIToolbar appearance]setBackgroundImage:navBarImage forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance]setTitleTextAttributes:@{ UITextAttributeTextColor: [UIColor whiteColor] }];
    [[UIBarButtonItem appearance]setTitleTextAttributes:@{ UITextAttributeTextColor: [UIColor whiteColor], UITextAttributeTextShadowColor: [UIColor clearColor] } forState:UIControlStateNormal];
    
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    if (!self.isReciever) {
        [self killSession];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application  {
    if (self.sessionController.session && !self.isReciever) {
        [self killSession];
        [self startSession];
    } else if (self.sessionController.session == nil) {
         [self startSession];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [[BGProcFactory sharedFactory]endAllTasks];
    [self killSession];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    [[NSURLCache sharedURLCache]removeAllCachedResponses];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    if (url.absoluteString.length == 0) {
        return NO;
    }
    
    if ([[DBSession sharedSession]handleOpenURL:url]) {
        if ([[DBSession sharedSession]isLinked]) {
            [[NSNotificationCenter defaultCenter]postNotificationName:@"db_auth_success" object:nil];
        } else {
            [[NSNotificationCenter defaultCenter]postNotificationName:@"db_auth_failure" object:nil];
        }
        return YES;
    }
    
    if ([url isFileURL]) {
        NSString *fileInDocsDir = getNonConflictingFilePathForPath([kDocsDir stringByAppendingPathComponent:[url.absoluteString lastPathComponent]]);
        NSString *inboxDir = [kDocsDir stringByAppendingPathComponent:@"Inbox"];
        NSString *fileInInboxDir = [inboxDir stringByAppendingPathComponent:[url.absoluteString lastPathComponent]];
        [[NSFileManager defaultManager]moveItemAtPath:fileInInboxDir toPath:fileInDocsDir error:nil];
        
        NSArray *filesInIndexDir = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:inboxDir error:nil];
        
        if (filesInIndexDir.count == 0) {
            [[NSFileManager defaultManager]removeItemAtPath:inboxDir error:nil];
        } else {
            for (NSString *string in filesInIndexDir) {
                NSString *newLocation = getNonConflictingFilePathForPath([kDocsDir stringByAppendingPathComponent:string]);
                NSString *oldLocation = [inboxDir stringByAppendingPathComponent:string];
                [[NSFileManager defaultManager]moveItemAtPath:oldLocation toPath:newLocation error:nil];
            }
            [[NSFileManager defaultManager]removeItemAtPath:inboxDir error:nil];
        }
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        fireNotification(url.absoluteString.lastPathComponent);
    } else {
        NSString *URLString = nil;
        if ([url.absoluteString hasPrefix:@"swiftload://"]) {
            URLString = [url.absoluteString stringByReplacingOccurrencesOfString:@"swiftload://" withString:@"http://"];
        } else {
            URLString = [url.absoluteString stringByReplacingOccurrencesOfString:@"dl://" withString:@"http://"];
        }
        [self downloadFromAppDelegate:URLString];
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

//
// BT Sending
//

- (void)showBTController {
    [self makeSessionUnavailable];
    GKPeerPickerController *peerPicker = [[GKPeerPickerController alloc]init];
    peerPicker.delegate = self;
    peerPicker.connectionTypesMask = GKPeerPickerConnectionTypeNearby;
    [peerPicker show];
}

- (void)sendBluetoothData {
    
    [self showHUDWithTitle:@"Sending File..."];
    
    NSString *fileName = [self.openFile lastPathComponent];
    
    if (fileName.length > 14) {
        fileName = [[fileName substringToIndex:11] stringByAppendingString:@"..."];
    }
    
    [self setSecondaryTitleOfVisibleHUD:fileName];
    
    NSString *filePath = self.openFile;
    
    if (filePath.length == 0) {
        filePath = [self nowPlayingFile];
    }
    
    if (filePath.length == 0) {
        [self hideHUD];
        [self.sessionControllerSending disconnect];
        [self setSessionControllerSending:nil];
        [self makeSessionAvailable];
        [TransparentAlert showAlertWithTitle:@"Internal Error" andMessage:@"The file could not be sent due to an internal error. Please try again later."];
        return;
    }
    
    NSData *file = [NSData dataWithContentsOfFile:filePath];
    NSString *fileNameSending = [filePath lastPathComponent];
    NSArray *array = [NSArray arrayWithObjects:fileNameSending, file, nil];
    NSData *finalData = [NSKeyedArchiver archivedDataWithRootObject:array];
    [self.sessionControllerSending sendDataToAllPeers:finalData];
    [[BGProcFactory sharedFactory]startProcForKey:@"Bluetooth" andExpirationHandler:nil];
}

- (void)peerPickerController:(GKPeerPickerController *)picker didConnectPeer:(NSString *)peerID toSession:(GKSession *)session {
    
    [[[[TransparentAlert alloc]initWithTitle:@"Connected" message:@"Would you like to send the file?" completionBlock:^(NSUInteger buttonIndex, UIAlertView *alertView) {
        
        if (buttonIndex == 1) {
            [self sendBluetoothData];
        } else {
            [session disconnectFromAllPeers];
        }
        
    } cancelButtonTitle:@"Cancel" otherButtonTitles:@"Send", nil]autorelease]show];
    
    BKSessionController *sTemp = [[BKSessionController alloc]initWithSession:session];
    self.sessionControllerSending = sTemp;
    [sTemp release];
    
    self.sessionControllerSending.delegate = self;
    
    picker.delegate = nil;
    [picker dismiss];
}

- (void)peerPickerControllerDidCancel:(GKPeerPickerController *)picker {
	picker.delegate = nil;
    [self makeSessionAvailable];
}

- (void)sessionControllerSenderDidReceiveData {
    if ([MBProgressHUD HUDForView:self.window].mode != MBProgressHUDModeDeterminate) {
        [self setVisibleHudMode:MBProgressHUDModeDeterminate];
    }
    [self setProgressOfVisibleHUD:self.sessionControllerSending.progress];
}

- (void)sessionControllerSenderDidFinishSendingData:(NSNotification *)aNotification {
    [self hideHUD];
    [TransparentAlert showAlertWithTitle:@"Sent" andMessage:@"Your file has been successfully sent."];
    [self.sessionControllerSending disconnect];
    [self setSessionControllerSending:nil];
    [self makeSessionAvailable];
    [[BGProcFactory sharedFactory]endProcForKey:@"Bluetooth"];
}

- (void)sessionControllerPeerDidDisconnect:(NSNotification *)aNotification {
    [self hideHUD];
    [TransparentAlert showAlertWithTitle:@"Bluetooth Disconnected" andMessage:@"The device you were connected to has been disconnected."];
    [self.sessionControllerSending.session disconnectFromAllPeers];
    [self setSessionControllerSending:nil];
    [self makeSessionAvailable];
    [[BGProcFactory sharedFactory]endProcForKey:@"Bluetooth"];
}

//
// BT Reciever methods
//

- (void)startSession {
    GKSession *session = [[GKSession alloc]initWithSessionID:nil displayName:nil sessionMode:GKSessionModeServer]; // change to peer
    BKSessionController *scTemp = [[BKSessionController alloc]initWithSession:session];
    [session release];
    [self setSessionController:scTemp];
    [scTemp release];
    self.sessionController.delegate = self;
    self.sessionController.session.delegate = self;
    self.sessionController.session.available = YES;
}

- (void)killSession {
    [self.sessionController setSession:nil];
    [self setSessionController:nil];
}

- (void)makeSessionUnavailable {
    self.sessionController.session.available = NO;
} 

- (void)makeSessionAvailable {
    self.sessionController.session.available = YES;
}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID {
    
    if ([MBProgressHUD HUDForView:self.window]) {
        [self.sessionController.session denyConnectionFromPeer:peerID];
    }
    
    [[[[TransparentAlert alloc]initWithTitle:@"Connect?" message:@"Another person is trying to send you a file over bluetooth." completionBlock:^(NSUInteger buttonIndex, UIAlertView *alertView) {
        
        if (buttonIndex == 1) {
            [self.sessionController.session acceptConnectionFromPeer:peerID error:nil];
        } else {
            [self.sessionController.session denyConnectionFromPeer:peerID];
        }
        
    } cancelButtonTitle:@"Cancel" otherButtonTitles:@"Connect", nil]autorelease]show];
}

- (void)sessionControllerReceiverWillStartReceivingData:(NSNotification *)aNotification {
    
    [[BGProcFactory sharedFactory]startProcForKey:@"bt_rec" andExpirationHandler:nil];
    
    self.isReciever = YES;
    
    [self showHUDWithTitle:@"Receiving File..."];
    [self setVisibleHudMode:MBProgressHUDModeDeterminate];
}

- (void)sessionControllerReceiverDidReceiveData:(NSNotification *)aNotification {
    [self setProgressOfVisibleHUD:self.sessionController.progress];
}

- (void)sessionControllerReceiverDidFinishReceivingData:(NSNotification *)aNotification {
    self.isReciever = NO;
    NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithData:self.sessionController.receivedData];
    
    if (array.count == 0) {
        [TransparentAlert showAlertWithTitle:@"File Transfer Failed" andMessage:@"There was an error receiving your file."];
        return;
    }
    
    NSData *file = [array objectAtIndex:1];
    NSString *name = [array objectAtIndex:0];
    NSString *docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
    
    [self hideHUD];
    
    NSString *finalLocation = getNonConflictingFilePathForPath([docsDir stringByAppendingPathComponent:name]);
    [[NSFileManager defaultManager]createFileAtPath:finalLocation contents:file attributes:nil];
    [self.sessionController.receivedData setLength:0];
    
    [[BGProcFactory sharedFactory]endProcForKey:@"bt_rec"];
    
    [TransparentAlert showAlertWithTitle:@"Success" andMessage:@"Your file was successfully received."];
}

//
// SFTP Download
//

- (void)downloadFileUsingSFTP:(NSURL *)url withUsername:(NSString *)username andPassword:(NSString *)password {
    SFTPDownload *download = [SFTPDownload downloadWithURL:url username:username andPassword:password];
    [[Downloads sharedDownloads]addDownload:download];
}

//
// FTP Download
//

- (void)downloadFileUsingFtp:(NSString *)url {
    [self downloadFileUsingFtp:url withUsername:@"anonymous" andPassword:@""];
}

- (void)downloadFileUsingFtp:(NSString *)url withUsername:(NSString *)username andPassword:(NSString *)password {
    FTPDownload *download = [FTPDownload downloadWithURL:[NSURL URLWithString:url]];
    download.username = username;
    download.password = password;
    [[Downloads sharedDownloads]addDownload:download];
}

//
// FTP Upload
//

- (void)uploadFinished:(SCRFTPRequest *)request {
    [self hideHUD];
    
    //[self showFinishedAlertForFilename:[request.ftpURL.absoluteString lastPathComponent]];
    [request release];
}

- (void)uploadFailed:(SCRFTPRequest *)request {
    [self hideHUD];
    NSString *message = [NSString stringWithFormat:@"Your file was not uploaded because %@", [request.error localizedDescription]];
    [TransparentAlert showAlertWithTitle:@"Upload Failed" andMessage:message];
    [request release];
}

- (void)uploadWillStart:(SCRFTPRequest *)request {
    [self showHUDWithTitle:@"Uploading..."];
    [self setSecondaryTitleOfVisibleHUD:[request.ftpURL.absoluteString lastPathComponent]];
    [self setVisibleHudMode:MBProgressHUDModeDeterminate];
}

- (void)uploadBytesWritten:(SCRFTPRequest *)request {
    [self setProgressOfVisibleHUD:[MBProgressHUD HUDForView:self.window].progress+(request.bytesWritten/request.fileSize)];
}

- (void)showFTPUploadController {
    FTPLoginController *controller = [[[FTPLoginController alloc]initWithType:FTPLoginControllerTypeUpload andCompletionHandler:^(NSString *username, NSString *password, NSString *url) {
        SCRFTPRequest *ftpRequest = [[SCRFTPRequest requestWithURL:[NSURL URLWithString:url] toUploadFile:self.openFile]retain];
        ftpRequest.username = username;
        ftpRequest.password = password;
        ftpRequest.delegate = self;
        ftpRequest.didFinishSelector = @selector(uploadFinished:);
        ftpRequest.didFailSelector = @selector(uploadFailed:);
        ftpRequest.willStartSelector = @selector(uploadWillStart:);
        ftpRequest.bytesWrittenSelector = @selector(uploadBytesWritten:);
        [ftpRequest startRequest];
    }]autorelease];
    [controller show];
}

- (void)dealloc {
    [self setWindow:nil];
    [self setViewController:nil];
    [self setSessionController:nil];
    [self setSessionControllerSending:nil];
    [self setOpenFile:nil];
    [self setNowPlayingFile:nil];
    [self setProgressView:nil];
    [self setManagerCurrentDir:nil];
    NSLog(@"%@ dealloc'd", NSStringFromClass([self class]));
    [super dealloc];
}

@end