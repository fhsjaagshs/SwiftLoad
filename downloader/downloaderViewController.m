//
//  downloaderViewController.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 8/11/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import "downloaderViewController.h"

void audioRouteChangeListenerCallback(void *inUserData, AudioSessionPropertyID inPropertyID, UInt32 inPropertyValueSize, const void *inPropertyValue) {
    
    if (inPropertyID == kAudioSessionProperty_AudioRouteChange) {
        CFNumberRef routeChangeReasonRef = CFDictionaryGetValue((CFDictionaryRef)inPropertyValue, CFSTR(kAudioSession_AudioRouteChangeKey_Reason));
        
        SInt32 routeChangeReason;
        CFNumberGetValue(routeChangeReasonRef, kCFNumberSInt32Type, &routeChangeReason);
        
        if (routeChangeReason == kAudioSessionRouteChangeReason_OldDeviceUnavailable) {
            if ([_audioPlayer isPlaying]) {
                [_audioPlayer pause];
            }
        }
    }
}


@implementation downloaderViewController

@synthesize textField, audioPlayer;

- (void)loadView {
    [super loadView];
    self.view.backgroundColor = [UIColor clearColor];
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    CustomNavBar *bar = [[CustomNavBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)];
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"SwiftLoad"];
    topItem.leftBarButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"WebDav" style:UIBarButtonItemStyleBordered target:self action:@selector(showWebDAVController)]autorelease];
    topItem.rightBarButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@" Web " style:UIBarButtonItemStyleBordered target:self action:@selector(showWebBrowser)]autorelease];
    [bar pushNavigationItem:topItem animated:NO];
    [self.view addSubview:bar];
    [self.view bringSubviewToFront:bar];
    [bar release];
    [topItem release];
    
    CustomToolbar *bottomBar = [[CustomToolbar alloc]initWithFrame:CGRectMake(0, screenBounds.size.height-44, screenBounds.size.width, 44)];
    bottomBar.items = [NSArray arrayWithObjects:[[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]autorelease], [[[UIBarButtonItem alloc]initWithTitle:@"Settings" style:UIBarButtonItemStyleBordered target:self action:@selector(showSettings)]autorelease], nil];
    [self.view addSubview:bottomBar];
    [self.view bringSubviewToFront:bottomBar];
    [bottomBar release];
    
    float height = screenBounds.size.height;
    
    BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    
    CustomButton *button = [[CustomButton alloc]initWithFrame:iPad?CGRectMake(312, 463, 144, 52):CGRectMake(112, 0.543*height, 96, 37)];
    [button setTitle:@"Download" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(download) forControlEvents:UIControlEventTouchUpInside];
    
    CustomButton *files = [[CustomButton alloc]initWithFrame:iPad?CGRectMake(334, 583, 101, 52):CGRectMake(124, 0.676*height, 72, 37)];
    [files setTitle:@"Files" forState:UIControlStateNormal];
    [files addTarget:self action:@selector(showFiles) forControlEvents:UIControlEventTouchUpInside];
    
    if (iPad) {
        [button.titleLabel setFont:[UIFont boldSystemFontOfSize:23]];
        [files.titleLabel setFont:[UIFont boldSystemFontOfSize:23]];
    }
    
    UILabel *swiftLoad = [[UILabel alloc]initWithFrame:iPad?CGRectMake(0, 51, 768, 254):CGRectMake(0, 0.117*height, 320, 106)];
    swiftLoad.text = @"SwiftLoad";
    swiftLoad.font = [UIFont boldSystemFontOfSize:iPad?110:60];
    swiftLoad.textColor = [UIColor colorWithRed:0.0f green:1.0f blue:1.0f alpha:1.0f];
    swiftLoad.textAlignment = UITextAlignmentCenter;
    swiftLoad.layer.shadowColor = [UIColor colorWithRed:105.0f/255.0f green:179.0f/255.0f blue:216.0f/255.0f alpha:1.0].CGColor;
    swiftLoad.layer.shadowRadius = 10.0f;
    swiftLoad.layer.shadowOpacity = 1.0f;
    swiftLoad.backgroundColor = [UIColor clearColor];
    
    UIButton *swiftLoadButton = [UIButton buttonWithType:UIButtonTypeCustom];
    swiftLoadButton.frame = swiftLoad.frame;
    [swiftLoadButton addTarget:self action:@selector(showAboutAlert) forControlEvents:UIControlEventTouchUpInside];
    swiftLoadButton.backgroundColor = [UIColor clearColor];
    
    [self.view addSubview:swiftLoadButton];
    [self.view bringSubviewToFront:swiftLoadButton];
    
    [self.view addSubview:swiftLoad];
    [self.view bringSubviewToFront:swiftLoad];
    [swiftLoad release];
    
    [self.view addSubview:button];
    [button release];
    
    [self.view addSubview:files];
    [self.view bringSubviewToFront:files];
    [files release];

    self.textField = [[[UITextField alloc]initWithFrame:iPad?CGRectMake(20, 335, 728, 31):CGRectMake(5, 0.343*height, 310, 31)]autorelease];
    self.textField.borderStyle = UITextBorderStyleRoundedRect;
    self.textField.placeholder = @"Enter URL for download here...";
    [self.textField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self.textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [self.textField setReturnKeyType:UIReturnKeyDone];
    [self.textField setClearButtonMode:UITextFieldViewModeWhileEditing];
    self.textField.adjustsFontSizeToFitWidth = YES;
    self.textField.font = [UIFont systemFontOfSize:12];
    self.textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.textField.textAlignment = UITextAlignmentLeft;
    [self.textField addTarget:self action:@selector(save) forControlEvents:UIControlEventEditingDidEndOnExit];
    [self.view addSubview:self.textField];
    [self.view bringSubviewToFront:self.textField];
    
    [[AVAudioSession sharedInstance]setCategory:AVAudioSessionCategoryPlayback error:nil];
    [self.textField setText:[[NSUserDefaults standardUserDefaults]objectForKey:@"myDefaults"]];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillDisappear) name:UIKeyboardWillHideNotification object:nil];
}

//
// Audio Player
//

- (void)artworksForFileAtPath:(NSString *)path block:(void(^)(NSArray *artworkImages))block {
    
    NSURL *url = [NSURL fileURLWithPath:path];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    NSArray *keys = [NSArray arrayWithObjects:@"commonMetadata", nil];
    [asset loadValuesAsynchronouslyForKeys:keys completionHandler:^{
        NSArray *artworks = [AVMetadataItem metadataItemsFromArray:asset.commonMetadata withKey:AVMetadataCommonKeyArtwork keySpace:AVMetadataKeySpaceCommon];
        
        NSMutableArray *artworkImages = [NSMutableArray array];
        for (AVMetadataItem *item in artworks) {
            NSString *keySpace = item.keySpace;
            
            UIImage *image = nil;
            
            if ([keySpace isEqualToString:AVMetadataKeySpaceID3]) {
                NSDictionary *d = [item.value copyWithZone:nil];
                image = [UIImage imageWithData:[d objectForKey:@"data"]];
                [d release];
            } else if ([keySpace isEqualToString:AVMetadataKeySpaceiTunes]) {
                NSData *data = [item.value copyWithZone:nil];
                image = [UIImage imageWithData:data];
                [data release];
            }
            
            if (image != nil) {
                [artworkImages addObject:image];
            }
        }
        
        if (block) {
            block(artworkImages);
        }
    }];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication]beginReceivingRemoteControlEvents];
    
    if (![self isFirstResponder]) {
        [self becomeFirstResponder];
    }
    
    AudioSessionRemovePropertyListenerWithUserData(kAudioSessionProperty_AudioRouteChange, audioRouteChangeListenerCallback, self);
    AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, audioRouteChangeListenerCallback, self);
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
    } else {
        [self.audioPlayer pause];
    }
}

- (void)turnOnAudioPlayerListeners {
    [[UIApplication sharedApplication]beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
    id weakself = __unsafe_unretained self;
    AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, audioRouteChangeListenerCallback, weakself);
}

- (void)turnOffAudioPlayerListeners {
    [[UIApplication sharedApplication]endReceivingRemoteControlEvents];
    [self resignFirstResponder];
    id weakself = __unsafe_unretained self;
    AudioSessionRemovePropertyListenerWithUserData(kAudioSessionProperty_AudioRouteChange, audioRouteChangeListenerCallback, weakself);
}

- (void)skipToPreviousTrack {
    
    if (self.audioPlayer.currentTime > 5) {
        self.audioPlayer.currentTime = 0;
        return;
    }
    
    [AudioPlayerViewController notif_setNxtTrackHidden:NO];

    NSString *cellNameFileKey = [kAppDelegate nowPlayingFile];
    
    NSString *currentDir = [cellNameFileKey stringByDeletingLastPathComponent];
    
    NSMutableArray *filesOfDir = [[[[NSFileManager defaultManager]contentsOfDirectoryAtPath:currentDir error:nil]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]mutableCopy];
    
    NSMutableArray *audioFiles = [NSMutableArray array];
    
    for (NSString *object in filesOfDir) {
        NSString *newObject = [currentDir stringByAppendingPathComponent:object];
        BOOL isAudio = [MIMEUtils isAudioFile:newObject];
        if (isAudio) {
            [audioFiles addObject:newObject];
        }
    }
    [filesOfDir release];
    
    int number = [audioFiles indexOfObject:cellNameFileKey]-1;
    
    if (number < 0) {
        return;
    }
    
    if (number+1 > audioFiles.count) {
        [AudioPlayerViewController notif_setPrevTrackHidden:YES];
        return;
    }
    
    if (number == 0) {
        [AudioPlayerViewController notif_setPrevTrackHidden:YES];
    }
    
    NSString *newFile = [audioFiles objectAtIndex:number];
    [kAppDelegate setOpenFile:newFile];
    
    NSURL *url = [NSURL fileURLWithPath:newFile];
    NSError *playingError = nil;
    
    [self.audioPlayer stop];
    self.audioPlayer = [[[AVAudioPlayer alloc]initWithContentsOfURL:url error:&playingError]autorelease];
    self.audioPlayer.delegate = self;
    
    [AudioPlayerViewController notif_setSongTitleText:[newFile lastPathComponent]];
    
    NSArray *iA = [metadataRetriever getMetadataForFile:newFile];
    NSString *artist = [iA objectAtIndex:0];
    NSString *title = [iA objectAtIndex:1];
    NSString *album = [iA objectAtIndex:2];
    NSString *metadata = [NSString stringWithFormat:@"%@\n%@\n%@",artist,title,album];
    [AudioPlayerViewController notif_setInfoFieldText:metadata];
    
    [self showMetadataInLockscreenWithArtist:artist title:title album:album];
    [self showArtworkForFile:newFile];

    NSString *savedLoop = [kLibDir stringByAppendingPathComponent:@"loop.txt"];
    NSString *loopContents = [NSString stringWithContentsOfFile:savedLoop encoding:NSUTF8StringEncoding error:nil];

    if ([loopContents isEqualToString:@"loop"]) {
        [self.audioPlayer setNumberOfLoops:-1];
    } else {
        [self.audioPlayer setNumberOfLoops:0];
    }
    
    [AudioPlayerViewController notif_setLoop];
    
    [self.audioPlayer play];

    if (playingError == nil) {
        [kAppDelegate setNowPlayingFile:newFile];
        [AudioPlayerViewController notif_setControlsHidden:YES];
    } else {
        [kAppDelegate setNowPlayingFile:nil];
        [AudioPlayerViewController notif_setControlsHidden:NO];
    }
}

- (void)skipToNextTrack {
    
    [AudioPlayerViewController notif_setPrevTrackHidden:NO];

    NSString *cellNameFileKey = [kAppDelegate nowPlayingFile];
    NSString *currentDir = [cellNameFileKey stringByDeletingLastPathComponent];
    
    NSArray *filesOfDir = [[[[NSFileManager defaultManager]contentsOfDirectoryAtPath:currentDir error:nil]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]mutableCopy];
    NSMutableArray *audioFiles = [NSMutableArray array];
    
    for (NSString *object in filesOfDir) {
        NSString *newObject = [currentDir stringByAppendingPathComponent:object];
        if ([MIMEUtils isAudioFile:newObject]) {
            [audioFiles addObject:newObject];
        }
    }
    [filesOfDir release];
    
    int number = [audioFiles indexOfObject:cellNameFileKey]+1;
    
    if (number < 0) {
        return;
    }
    
    if (number-1 > audioFiles.count) {
        [AudioPlayerViewController notif_setNxtTrackHidden:YES];
        return;
    }

    if (number == audioFiles.count) {
        return;
    }
    
    if (number == audioFiles.count-1) {
        [AudioPlayerViewController notif_setNxtTrackHidden:YES];
    }
    
    NSString *newFile = [audioFiles objectAtIndex:number];
    [kAppDelegate setOpenFile:newFile];
    
    NSURL *url = [NSURL fileURLWithPath:newFile];
    NSError *playingError = nil;
    
    [self.audioPlayer stop];
    self.audioPlayer = [[[AVAudioPlayer alloc]initWithContentsOfURL:url error:&playingError]autorelease];
    self.audioPlayer.delegate = self;
    
    [AudioPlayerViewController notif_setSongTitleText:[newFile lastPathComponent]];
    
    NSArray *iA = [metadataRetriever getMetadataForFile:newFile];
    NSString *artist = [iA objectAtIndex:0];
    NSString *title = [iA objectAtIndex:1];
    NSString *album = [iA objectAtIndex:2];
    NSString *metadata = [NSString stringWithFormat:@"%@\n%@\n%@",artist,title,album];
    [AudioPlayerViewController notif_setInfoFieldText:metadata];

    [self showMetadataInLockscreenWithArtist:artist title:title album:album];
    [self showArtworkForFile:newFile];
    
    NSString *savedLoop = [kLibDir stringByAppendingPathComponent:@"loop.txt"];
    NSString *loopContents = [NSString stringWithContentsOfFile:savedLoop encoding:NSUTF8StringEncoding error:nil];

    if ([loopContents isEqualToString:@"loop"]) {
        [self.audioPlayer setNumberOfLoops:-1];
    } else {
        [self.audioPlayer setNumberOfLoops:0];
    }
    
    [AudioPlayerViewController notif_setLoop];

    [self.audioPlayer play];

    if (playingError == nil) {
        [kAppDelegate setNowPlayingFile:newFile];
        [AudioPlayerViewController notif_setControlsHidden:YES];
    } else {
        [kAppDelegate setNowPlayingFile:nil];
        [AudioPlayerViewController notif_setControlsHidden:NO];
    }
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
    }
    
    if (![self nextTrackButtonShouldBeHidden]) {
        [self.audioPlayer setCurrentTime:0];
        [AudioPlayerViewController notif_setPausePlayTitlePlay];
    }
}

- (BOOL)nextTrackButtonShouldBeHidden {
    
    NSString *cellNameFileKey = [kAppDelegate nowPlayingFile];
    NSString *currentDir = [cellNameFileKey stringByDeletingLastPathComponent];
    
    NSArray *filesOfDir = [[[[NSFileManager defaultManager]contentsOfDirectoryAtPath:currentDir error:nil]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]mutableCopy];
    NSMutableArray *audioFiles = [NSMutableArray array];
    
    for (NSString *object in filesOfDir) {
        NSString *newObject = [currentDir stringByAppendingPathComponent:object];
        if ([MIMEUtils isAudioFile:newObject]) {
            [audioFiles addObject:newObject];
        }
    }

    [filesOfDir release];

    if ([audioFiles indexOfObject:cellNameFileKey] == audioFiles.count-2) {
        return YES;
    }
    return NO;
}

//
// Main Functionality
//

- (void)keyboardWillDisappear {
    [[NSUserDefaults standardUserDefaults]setObject:self.textField.text forKey:@"myDefaults"];
}

- (void)download {
    [self save];
    if (self.textField.text.length > 0) {
        
        if ([self.textField.text hasPrefix:@"http"]) {
            [kAppDelegate downloadFromAppDelegate:self.textField.text];
        }
    }
}

- (void)save {
    if ([self.textField isFirstResponder]) {
        [self.textField resignFirstResponder];
    }
    [[NSUserDefaults standardUserDefaults]setObject:self.textField.text forKey:@"myDefaults"];
}

- (void)showFiles {
    [[UIApplication sharedApplication]cancelAllLocalNotifications];
    MyFilesViewController *filesViewMe = [[MyFilesViewController alloc]initWithAutoNib];
    filesViewMe.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self presentModalViewController:filesViewMe animated:YES];
    [filesViewMe release];
}

- (void)showWebBrowser {
    webBrowser *wb = [webBrowser viewController];
    wb.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentModalViewController:wb animated:YES];
}

- (void)showWebDAVController {
    webDAVViewController *advc = [webDAVViewController viewController];
    advc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentModalViewController:advc animated:YES];
}

- (void)showAboutAlert {
    [self save];
    NSString *version = [[[NSBundle mainBundle]infoDictionary]objectForKey:@"CFBundleShortVersionString"];
    NSString *title = [NSString stringWithFormat:@"SwiftLoad v%@\nBy Nathaniel Symer",version];
    
    CustomAlertView *av = [[CustomAlertView alloc]initWithTitle:title message:@"Maintaining the UNIX spirit since 2011." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [av show];
    [av release];
}

- (void)showSettings {
    SettingsView *d = [SettingsView viewController];
    d.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentModalViewController:d animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self save];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
}

- (NSUInteger)supportedInterfaceOrientations {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationMaskAll;
    }
    return UIInterfaceOrientationMaskPortrait;
}

- (void)dealloc {
    [self setTextField:nil];
    [self setAudioPlayer:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    NSLog(@"%@ dealloc'd", NSStringFromClass([self class]));
    [super dealloc];
}

@end
