//
//  downloaderAppDelegate.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 8/11/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import "downloaderAppDelegate.h"
#import "HatchedView.h"

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
        
        path = [[[oldPath stringByDeletingPathExtension]stringByAppendingString:[NSString stringWithFormat:@" - %d",appendNumber]]stringByAppendingPathExtension:ext];
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

@synthesize sessionController, progressView, isReciever, nowPlayingFile, sessionControllerSending, openFile, managerCurrentDir, restClient, downloadedData, expectedDownloadingFileSize, downloadedBytes, audioPlayer;

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
        CustomAlertView *av = [[CustomAlertView alloc]initWithTitle:@"Mail Unavailable" message:@"In order to use this functionality, you must set up an email account in Settings." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [av show];
        [av release];
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
                    NSString *message = [NSString stringWithFormat:@"Error %u: %@", error.code, error.domain];
                    CustomAlertView *av = [[CustomAlertView alloc]initWithTitle:@"Error Printing" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [av show];
                    [av release];
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

- (void)showFinishedAlertForFilename:(NSString *)fileName {
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
    
    [self showHUDWithTitle:@"Completed"];
    [self setSecondaryTitleOfVisibleHUD:fileName];
    [self setVisibleHudCustomView:[[[UIImageView alloc]initWithImage:getCheckmarkImage()]autorelease]];
    [self hideVisibleHudAfterDelay:1.5f];
}

- (void)showExistsAlertForFilename:(NSString *)fnZ {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if (fnZ.length > 14) {
        fnZ = [[fnZ substringToIndex:11]stringByAppendingString:@"..."];
    }
    
    UILocalNotification *notification = [[UILocalNotification alloc]init];
    notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
    notification.alertBody = [NSString stringWithFormat:@"%@ already exists",fnZ];
    notification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication]presentLocalNotificationNow:notification];
    [notification release];

    CustomAlertView *av = [[CustomAlertView alloc]initWithTitle:@"File Exists" message:[NSString stringWithFormat:@"\"%@\" already exists.",fnZ] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [av show];
    [av release];
}

- (void)showFailedAlertForFilename:(NSString *)fileName {
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
    
    NSString *message = [NSString stringWithFormat:@"SwiftLoad failed to download \"%@\". Please try again later.",fileName];
    CustomAlertView *av = [[CustomAlertView alloc]initWithTitle:@"Oops..." message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [av show];
    [av release];
}

- (void)downloadURL:(NSURL *)url {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    NSMutableURLRequest *headReq = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:30.0];
    [headReq setHTTPMethod:@"HEAD"];
    
    [NSURLConnection sendAsynchronousRequest:headReq queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (!error) {
            NSDictionary *headers = [(NSHTTPURLResponse *)response allHeaderFields];
            if (headers) {
                if ([headers objectForKey:@"Content-Range"]) {
                    NSString *contentRange = [headers objectForKey:@"Content-Range"];
                    NSRange range = [contentRange rangeOfString:@"/"];
                    NSString *totalBytesCount = [contentRange substringFromIndex: range.location + 1];
                    self.expectedDownloadingFileSize = [totalBytesCount floatValue];
                } else if ([headers objectForKey:@"Content-Length"]) {
                    self.expectedDownloadingFileSize = [[headers objectForKey:@"Content-Length"]floatValue];
                } else {
                    self.expectedDownloadingFileSize = -1;
                    [self setVisibleHudMode:MBProgressHUDModeIndeterminate];
                }
            }
            
            NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:30.0];
            [theRequest setHTTPMethod:@"GET"];
            self.connection = [[[NSURLConnection alloc]initWithRequest:theRequest delegate:self]autorelease];
            self.backgroundTaskIdentifier = [[UIApplication sharedApplication]beginBackgroundTaskWithExpirationHandler:^{
                
                [self.connection cancel];
                [self.downloadedData setLength:0];
                self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
                
                [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:NO];
                [[UIApplication sharedApplication]endBackgroundTask:self.backgroundTaskIdentifier];
            }];
        }
    }];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
    self.downloadingFileName = [response.URL.absoluteString lastPathComponent];
}

- (void)connection:(NSURLConnection *)theConnection didReceiveData:(NSData *)recievedData {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    if (self.downloadedData.length == 0) {
        self.downloadedData = [NSMutableData data];
    }
    
    self.downloadedBytes = self.downloadedBytes+recievedData.length;
    [self.downloadedData appendData:recievedData];
    float progress = self.downloadedData.length/self.expectedDownloadingFileSize;
    [self setProgressOfVisibleHUD:progress];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self hideHUD];
    [self showFailedAlertForFilename:[self.downloadingFileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)theConnection {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self hideHUD];
    NSString *filename = [self.downloadingFileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    if (self.downloadedData.length > 0) {
        NSString *filePath = getNonConflictingFilePathForPath([kDocsDir stringByAppendingPathComponent:filename]);
        [[NSFileManager defaultManager]createFileAtPath:filePath contents:self.downloadedData attributes:nil];
        [self showFinishedAlertForFilename:filename];
        [self.downloadedData setLength:0];
    } else {
        [self showFailedAlertForFilename:filename];
    }
}

- (void)downloadFromAppDelegate:(NSString *)stouPrelim {
    if (![stouPrelim hasPrefix:@"http"]) {
        
        if ([stouPrelim hasPrefix:@"ftp"] || [stouPrelim hasPrefix:@"sftp"] || [stouPrelim hasPrefix:@"rsync"] || [stouPrelim hasPrefix:@"afp"]) {
            [self showFailedAlertForFilename:[stouPrelim lastPathComponent]];
            return;
        }
        
        stouPrelim = [NSString stringWithFormat:@"http://%@",stouPrelim];
    }

    NSURL *url = [NSURL URLWithString:stouPrelim];

    if (url == nil) {
        [self showFailedAlertForFilename:[stouPrelim lastPathComponent]];
        return;
    }
    
    NSString *fileName = [[stouPrelim lastPathComponent]stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    if (fileName.length > 14) {
        fileName = [[fileName substringToIndex:11]stringByAppendingString:@"..."];
    }
    
    [self showHUDWithTitle:@"Downloading"];
    [self setVisibleHudMode:MBProgressHUDModeDeterminate];
    [self setSecondaryTitleOfVisibleHUD:fileName];
    [self downloadURL:url];
}

- (BOOL)isInForground {
    return ([[UIApplication sharedApplication]applicationState] == UIApplicationStateActive || [[UIApplication sharedApplication]applicationState] == UIApplicationStateInactive);
}

//
// Dropbox Upload
// 

- (void)uploadLocalFile:(NSString *)localPath {
    [self setOpenFile:localPath];
    [self showHUDWithTitle:@"Preparing"];
    [self setVisibleHudMode:MBProgressHUDModeIndeterminate];
    [self.restClient loadMetadata:@"/"];
}

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
    
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
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        [self setVisibleHudMode:MBProgressHUDModeDeterminate];
        [self setTitleOfVisibleHUD:@"Uploading..."];
        [self.restClient uploadFile:[self.openFile lastPathComponent] toPath:@"/" withParentRev:rev fromPath:self.openFile];
    }
}

- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self hideHUD];
    NSString *message = [NSString stringWithFormat:@"The file you tried to upload failed because: %@",error];
    CustomAlertView *avdd = [[CustomAlertView alloc]initWithTitle:@"Failure Uploading" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [avdd show];
    [avdd release];
}

- (void)restClient:(DBRestClient *)client uploadProgress:(CGFloat)progress forFile:(NSString *)destPath from:(NSString *)srcPath {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self setProgressOfVisibleHUD:progress];
}

- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath metadata:(DBMetadata *)metadata {
    [self.restClient loadSharableLinkForFile:metadata.path];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self hideHUD];
    NSString *message = [[NSString alloc]initWithFormat:@"The file you tried to upload failed because: %@",error];
    CustomAlertView *avdd = [[CustomAlertView alloc]initWithTitle:@"Failure Uploading" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [avdd show];
    [avdd release];
    [message release];
}

- (void)restClient:(DBRestClient *)client loadedSharableLink:(NSString *)link forFile:(NSString *)path {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self hideHUD];

    CustomAlertView *avdd = [[CustomAlertView alloc]initWithTitle:[NSString stringWithFormat:@"Link For:\n%@",[path lastPathComponent]] message:link completionBlock:^(NSUInteger buttonIndex, UIAlertView *alertView) {
        if (buttonIndex == 1) {
            [[UIPasteboard generalPasteboard]setString:alertView.message];
        }
    } cancelButtonTitle:@"OK" otherButtonTitles:@"Copy", nil];

    [avdd show];
    [avdd release];
}

- (void)restClient:(DBRestClient *)client loadSharableLinkFailedWithError:(NSError *)error {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self setProgressOfVisibleHUD:1.0f];
    [self hideHUD];
    CustomAlertView *avdd = [[CustomAlertView alloc]initWithTitle:@"Success Uploading" message:@"Upload succeeded, but there was a problem generating a sharable link." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [avdd show];
    [avdd release];
}

- (void)sessionDidReceiveAuthorizationFailure:(DBSession *)session userId:(NSString *)userId {
    CustomAlertView *avD = [[CustomAlertView alloc]initWithTitle:@"Failed Dropbox Authentication" message:@"Please try reauthenticating in the settings page on the main menu." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[avD show];
    [avD release];
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

    [[AVAudioSession sharedInstance]setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[UIApplication sharedApplication]beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
    AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, audioRouteChangeListenerCallback, nil);
    
    self.window = [[[UIWindow alloc]initWithFrame:[[UIScreen mainScreen]bounds]]autorelease];
    self.viewController = [downloaderViewController viewController];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    
    HatchedView *hatchedView = [[HatchedView alloc]initWithFrame:self.window.bounds];
    [self.window addSubview:hatchedView];
    [self.window sendSubviewToBack:hatchedView];
    [hatchedView release];
    
    DBSession *session = [[DBSession alloc]initWithAppKey:@"ybpwmfq2z1jmaxi" appSecret:@"ua6hjow7hxx0y3a" root:kDBRootDropbox];
	session.delegate = self;
	[DBSession setSharedSession:session];
    [session release];
    
    DBRestClient *rc = [[DBRestClient alloc]initWithSession:[DBSession sharedSession]];
    [self setRestClient:rc];
    [rc release];
    [self.restClient setDelegate:self];
    
    if (self.sessionController.session && !self.isReciever) {
        [self killSession];
        [self startSession];
    } else if (!self.sessionController.session) {
        [self startSession];
    }

    UIImage *bbiImage = [getButtonImage() resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)];
    [[UIBarButtonItem appearance]setBackgroundImage:bbiImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    
    UIImage *navBarImage = [getNavBarImage() resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)];
    [[UINavigationBar appearance]setBackgroundImage:navBarImage forBarMetrics:UIBarMetricsDefault];
    NSDictionary *navbarTitleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], UITextAttributeTextColor, [UIColor blackColor], UITextAttributeTextShadowColor, [NSValue valueWithUIOffset:UIOffsetMake(-0.5, -0.5)], UITextAttributeTextShadowOffset, nil];
    
    [[UINavigationBar appearance]setTitleTextAttributes:navbarTitleTextAttributes];
    
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
        
        [self showFinishedAlertForFilename:[url.absoluteString lastPathComponent]];
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
        CustomAlertView *av = [[CustomAlertView alloc]initWithTitle:@"Internal Error" message:@"The file could not be sent due to an internal error. Please try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [av show];
        return;
    }
    
    NSData *file = [NSData dataWithContentsOfFile:filePath];
    NSString *fileNameSending = [filePath lastPathComponent];
    NSArray *array = [NSArray arrayWithObjects:fileNameSending, file, nil];
    NSData *finalData = [NSKeyedArchiver archivedDataWithRootObject:array];
    [self.sessionControllerSending sendDataToAllPeers:finalData];
}

- (void)peerPickerController:(GKPeerPickerController *)picker didConnectPeer:(NSString *)peerID toSession:(GKSession *)session {
    
    CustomAlertView *avs = [[CustomAlertView alloc]initWithTitle:@"Connected" message:@"Would you like to send the file?" completionBlock:^(NSUInteger buttonIndex, UIAlertView *alertView) {
        
        if (buttonIndex == 1) {
            [self sendBluetoothData];
        } else {
            [session disconnectFromAllPeers];
        }
        
    } cancelButtonTitle:@"Cancel" otherButtonTitles:@"Send", nil];

    [avs show];
    [avs release];
    
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
    CustomAlertView *avs = [[CustomAlertView alloc]initWithTitle:@"Sent" message:@"Your file has been successfully sent." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [avs show];
    [avs release];
    [self.sessionControllerSending disconnect];
    [self setSessionControllerSending:nil];
    [self makeSessionAvailable];
}

- (void)sessionControllerPeerDidDisconnect:(NSNotification *)aNotification {
    [self hideHUD];
    CustomAlertView *avs = [[CustomAlertView alloc]initWithTitle:@"Disconnected" message:@"The device with which you were connected has been disconnected." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [avs show];
    [avs release];
    [self.sessionControllerSending.session disconnectFromAllPeers];
    [self setSessionControllerSending:nil];
    [self makeSessionAvailable];
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
    
    CustomAlertView *avs = [[CustomAlertView alloc]initWithTitle:@"Connect?" message:@"Another person is trying to send you a file over bluetooth." completionBlock:^(NSUInteger buttonIndex, UIAlertView *alertView) {
        
        if (buttonIndex == 1) {
            [self.sessionController.session acceptConnectionFromPeer:peerID error:nil];
        } else {
            [self.sessionController.session denyConnectionFromPeer:peerID];
        }
        
    } cancelButtonTitle:@"Cancel" otherButtonTitles:@"Connect", nil];
    
    [avs show];
    [avs release];
}

- (void)sessionControllerReceiverWillStartReceivingData:(NSNotification *)aNotification {
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
        CustomAlertView *av = [[CustomAlertView alloc]initWithTitle:@"Failure" message:@"There has been an error trying to receive your file." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [av show];
        [av release];
        return;
    }
    
    NSData *file = [array objectAtIndex:1];
    NSString *name = [array objectAtIndex:0];
    NSString *docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
    
    [self hideHUD];
    
    NSString *finalLocation = getNonConflictingFilePathForPath([docsDir stringByAppendingPathComponent:name]);
    [[NSFileManager defaultManager]createFileAtPath:finalLocation contents:file attributes:nil];
    [self.sessionController.receivedData setLength:0];
    
    CustomAlertView *av = [[CustomAlertView alloc]initWithTitle:@"Success" message:@"Your file has been successfully received." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [av show];
    [av release];
}

//
// FTP Upload
//

- (void)uploadFinished:(SCRFTPRequest *)request {
    [self hideHUD];
    NSString *filename = [self.openFile lastPathComponent];
    NSString *message = [NSString stringWithFormat:@"The file \"%@\" has sucessfully uploaded to the server.",filename];
    CustomAlertView *avs = [[CustomAlertView alloc]initWithTitle:@"Success" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [avs show];
    [avs release];
    [request release];
}

- (void)uploadFailed:(SCRFTPRequest *)request {
    [self hideHUD];
    NSString *message = [NSString stringWithFormat:@"Your file was not uploaded because %@", [request.error localizedDescription]];
    CustomAlertView *avs = [[CustomAlertView alloc]initWithTitle:@"Upload Failed" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [avs show];
    [avs release];
    [request release];
}

- (void)uploadWillStart:(SCRFTPRequest *)request {
    [self showHUDWithTitle:@"Uploading..."];
    [self setVisibleHudMode:MBProgressHUDModeDeterminate];
}

- (void)uploadBytesWritten:(SCRFTPRequest *)request {
    [self setProgressOfVisibleHUD:[MBProgressHUD HUDForView:self.window].progress+(request.bytesWritten/request.fileSize)];
}

- (void)actuallySend {
    [serverField resignFirstResponder];
    [usernameField resignFirstResponder];
    [passwordField resignFirstResponder];
    
    [[NSUserDefaults standardUserDefaults]setObject:serverField.text forKey:@"FTPPath"];
    [[NSUserDefaults standardUserDefaults]setObject:usernameField.text forKey:@"FTPUsername"];

    SCRFTPRequest *ftpRequest = [[SCRFTPRequest alloc]initWithURL:[NSURL URLWithString:serverField.text] toUploadFile:self.openFile];
    ftpRequest.username = usernameField.text;
    ftpRequest.password = passwordField.text;
    ftpRequest.delegate = self;
    ftpRequest.didFinishSelector = @selector(uploadFinished:);
    ftpRequest.didFailSelector = @selector(uploadFailed:);
    ftpRequest.willStartSelector = @selector(uploadWillStart:);
    ftpRequest.bytesWrittenSelector = @selector(uploadBytesWritten:);
    [ftpRequest startRequest];
}

- (void)showFTPUploadController {
    
    avL = [[[CustomAlertView alloc]initWithTitle:@"Enter FTP Info" message:@"\n\n\n\n\n" completionBlock:^(NSUInteger buttonIndex, UIAlertView *alertView) {
        if (buttonIndex == 1) {
            [self actuallySend];
        }
    } cancelButtonTitle:@"Cancel" otherButtonTitles:@"Upload", nil]autorelease];

    serverField = [[[CustomTextField alloc]initWithFrame:CGRectMake(13, 48, 257, 30)]autorelease];
    [serverField setKeyboardAppearance:UIKeyboardAppearanceAlert];
    [serverField setBorderStyle:UITextBorderStyleBezel];
    [serverField setBackgroundColor:[UIColor clearColor]];
    [serverField setReturnKeyType:UIReturnKeyNext];
    [serverField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [serverField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [serverField setPlaceholder:@"ftp://"];
    [serverField setFont:[UIFont boldSystemFontOfSize:18]];
    [serverField setAdjustsFontSizeToFitWidth:YES];
    [serverField setDelegate:self];
    [serverField setClearButtonMode:UITextFieldViewModeWhileEditing];
    serverField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    
    usernameField = [[[CustomTextField alloc]initWithFrame:CGRectMake(13, 85, 257, 30)]autorelease];
    [usernameField setKeyboardAppearance:UIKeyboardAppearanceAlert];
    [usernameField setBorderStyle:UITextBorderStyleBezel];
    [usernameField setBackgroundColor:[UIColor whiteColor]];
    [usernameField setReturnKeyType:UIReturnKeyNext];
    [usernameField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [usernameField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [usernameField setPlaceholder:@"Username"];
    [usernameField setFont:[UIFont boldSystemFontOfSize:18]];
    [usernameField setAdjustsFontSizeToFitWidth:YES];
    usernameField.delegate = self;
    usernameField.clearButtonMode = UITextFieldViewModeWhileEditing;
    usernameField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    
    passwordField = [[[CustomTextField alloc]initWithFrame:CGRectMake(13, 122, 257, 30)]autorelease];
    [passwordField setKeyboardAppearance:UIKeyboardAppearanceAlert];
    [passwordField setBorderStyle:UITextBorderStyleBezel];
    [passwordField setBackgroundColor:[UIColor whiteColor]];
    [passwordField setReturnKeyType:UIReturnKeyNext];
    [passwordField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [passwordField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [passwordField setPlaceholder:@"Password"];
    [passwordField setFont:[UIFont boldSystemFontOfSize:18]];
    [passwordField setAdjustsFontSizeToFitWidth:YES];
    passwordField.secureTextEntry = YES;
    passwordField.delegate = self;
    passwordField.clearButtonMode = UITextFieldViewModeWhileEditing;
    passwordField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    
    NSString *FTPPath = [[NSUserDefaults standardUserDefaults]objectForKey:@"FTPPath"];
    NSString *FTPUsername = [[NSUserDefaults standardUserDefaults]objectForKey:@"FTPUsername"];
    
    serverField.text = FTPPath;
    usernameField.text = FTPUsername;
    
    [serverField becomeFirstResponder];
    
    if (serverField.text.length > 0) {
        [usernameField becomeFirstResponder];
    }
    
    if (usernameField.text.length > 0) {
        [passwordField becomeFirstResponder];
    }
    
    [serverField addTarget:self action:@selector(moveOnServerField) forControlEvents:UIControlEventEditingDidEndOnExit];
    [usernameField addTarget:self action:@selector(moveOnUsernameField) forControlEvents:UIControlEventEditingDidEndOnExit];
    [passwordField addTarget:self action:@selector(dismissavL) forControlEvents:UIControlEventEditingDidEndOnExit];
    
    [avL addSubview:serverField];
    [avL addSubview:usernameField];
    [avL addSubview:passwordField];
    [avL show];
}

- (void)moveOnServerField {
    if ([serverField isFirstResponder]) {
        [serverField resignFirstResponder];
    }
    [usernameField becomeFirstResponder];
}

- (void)moveOnUsernameField {
    if ([usernameField isFirstResponder]) {
        [usernameField resignFirstResponder];
    }
    [passwordField becomeFirstResponder];
}

- (void)dismissavL {
    if ([serverField isFirstResponder]) {
        [serverField resignFirstResponder];
    }
}

- (void)dealloc {
    [self setWindow:nil];
    [self setViewController:nil];
    [self setConnection:nil];
    [self setDownloadingFileName:nil];
    [self setDownloadedData:nil];
    [self setRestClient:nil];
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