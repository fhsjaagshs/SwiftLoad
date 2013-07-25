//
//  AudioPlayerViewController.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 8/11/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import "AudioPlayerViewController.h"

@implementation AudioPlayerViewController

- (void)loadView {
    [super loadView];
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    
    self.navBar = [[ShadowedNavBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)];
    self.navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:[[kAppDelegate openFile]lastPathComponent]];
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showActionSheet:)];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    [self.navBar pushNavigationItem:topItem animated:YES];
    [self.view addSubview:self.navBar];
    [self.view bringSubviewToFront:self.navBar];
    
    BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    
    self.time = [[UISlider alloc]initWithFrame:CGRectMake(5, iPad?357:sanitizeMesurement(219), screenBounds.size.width-10, 23)];
    [_time setMinimumTrackTintColor:[UIColor colorWithRed:21.0f/255.0f green:92.0f/255.0f blue:136.0f/255.0f alpha:1.0f]];
    [_time setMaximumTrackTintColor:[UIColor colorWithRed:105.0f/255.0f green:179.0f/255.0f blue:216.0f/255.0f alpha:1.0]];
    [self.time addTarget:self action:@selector(sliderChanged) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.time];
    
    self.prevTrack = [[UIButton alloc]initWithFrame:iPad?CGRectMake(20, 533, 142, 51):CGRectMake(20, sanitizeMesurement(270), 72, 45)];
    self.prevTrack.backgroundColor = [UIColor clearColor];
    [self.prevTrack setImage:[UIImage imageNamed:@"back_button"] forState:UIControlStateNormal];
    [self.prevTrack setImage:[UIImage imageNamed:@"back_button_pressed"] forState:UIControlStateHighlighted];
    [self.prevTrack addTarget:kAppDelegate action:@selector(skipToPreviousTrack) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.prevTrack];
    
    self.nxtTrack = [[UIButton alloc]initWithFrame:iPad?CGRectMake(599, 533, 142, 51):CGRectMake(228, sanitizeMesurement(270), 72, 45)];
    self.nxtTrack.backgroundColor = [UIColor clearColor];
    [self.nxtTrack setImage:[UIImage imageNamed:@"next_button"] forState:UIControlStateNormal];
    [self.nxtTrack setImage:[UIImage imageNamed:@"next_button_pressed"] forState:UIControlStateHighlighted];
    [self.nxtTrack addTarget:kAppDelegate action:@selector(skipToNextTrack) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.nxtTrack];
    
    self.pausePlay = [[UIButton alloc]initWithFrame:iPad?CGRectMake(323, 533, 142, 51):CGRectMake(124, sanitizeMesurement(270), 72, 45)];
    self.pausePlay.backgroundColor = [UIColor clearColor];
    [self.pausePlay setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
    [self.pausePlay setImage:[UIImage imageNamed:@"pause_selected"] forState:UIControlStateHighlighted];
    [self.pausePlay addTarget:kAppDelegate action:@selector(togglePlayPause) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.pausePlay];
    
    self.infoField = [[UITextView alloc]initWithFrame:CGRectMake(0, 44, screenBounds.size.width, sanitizeMesurement(73))];
    self.infoField.textAlignment = UITextAlignmentCenter;
    self.infoField.textColor = [UIColor blackColor];
    self.infoField.font = [UIFont systemFontOfSize:15];
    self.infoField.editable = NO;
    self.infoField.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.infoField];
    
    self.loopControl = [[ToggleControl alloc]initWithFrame:CGRectMake(self.view.bounds.size.width-50, self.view.bounds.size.height-50-44, 40, 40)];
    [_loopControl addTarget:self action:@selector(saveLoopState) forControlEvents:UIControlEventTouchUpInside];
    self.loopControl.backgroundColor = [UIColor clearColor];
    [_loopControl setImage:[UIImage imageNamed:@"loop_on"] forState:ToggleControlModeOn];
    [_loopControl setImage:[UIImage imageNamed:@"loop_off"] forState:ToggleControlModeOff];
    [_loopControl setImage:[UIImage imageNamed:@"loop_pressed"] forState:ToggleControlModeIntermediate];
    [self.view addSubview:_loopControl];
    
    self.secondsRemaining = [[UILabel alloc]initWithFrame:iPad?CGRectMake(315, 220, 139, 35):CGRectMake(51, sanitizeMesurement(187), 112, 21)];
    self.secondsRemaining.text = @"Time Elapsed:";
    self.secondsRemaining.backgroundColor = [UIColor clearColor];
    self.secondsRemaining.textColor = [UIColor blackColor];
    self.secondsRemaining.font = iPad?[UIFont boldSystemFontOfSize:20]:[UIFont systemFontOfSize:17];
    [self.view addSubview:self.secondsRemaining];
    
    self.secondsDisplay = [[UILabel alloc]initWithFrame:iPad?CGRectMake(0, 263, 768, 55):CGRectMake(164, sanitizeMesurement(185), 136, 27)];
    self.secondsDisplay.font = [UIFont boldSystemFontOfSize:iPad?39:24];
    self.secondsDisplay.textColor = [UIColor blackColor];
    self.secondsDisplay.backgroundColor = [UIColor clearColor];
    self.secondsDisplay.textAlignment = iPad?UITextAlignmentCenter:UITextAlignmentLeft;
    self.secondsDisplay.text = @"0:00";
    [self.view addSubview:self.secondsDisplay];
    
    self.errorLabel = [[UILabel alloc]initWithFrame:iPad?CGRectMake(14, 311, 727, 113):CGRectMake(4, sanitizeMesurement(149), 313, 57)];
    self.errorLabel.text = @"Error Playing Audio";
    self.errorLabel.backgroundColor = [UIColor clearColor];
    self.errorLabel.textColor = [UIColor blackColor];
    self.errorLabel.font = [UIFont boldSystemFontOfSize:iPad?72:33];
    [self.view addSubview:self.errorLabel];
    
    UIToolbar *toolBar = [[ShadowedToolbar alloc]initWithFrame:CGRectMake(0, screenBounds.size.height-44, screenBounds.size.width, 44)];
    toolBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    
    MPVolumeView *volView = [[MPVolumeView alloc]initWithFrame:CGRectMake(0, 12, screenBounds.size.width-25, 20)];
    volView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    
    for (UIView *view in volView.subviews) {
        if ([[[view class]description]isEqualToString:@"MPVolumeSlider"]) {
            UIView *a = view;
            [(UISlider *)a setThumbTintColor:self.time.thumbTintColor];
            [(UISlider *)a setMinimumTrackTintColor:self.time.minimumTrackTintColor];
            [(UISlider *)a setMaximumTrackTintColor:[UIColor lightGrayColor]];
            [(UISlider *)a setBackgroundColor:[UIColor clearColor]];
            [(UISlider *)a setThumbImage:nil forState:UIControlStateNormal];
        }
    }
    
    UIBarButtonItem *volume = [[UIBarButtonItem alloc]initWithCustomView:volView];
    
    toolBar.items = [NSArray arrayWithObjects:volume, nil];
    [self.view addSubview:toolBar];
    [self.view bringSubviewToFront:toolBar];
    
    [self setupNotifs];
    
    AppDelegate *ad = kAppDelegate;
    
    NSString *file = ad.openFile;
    NSString *currentDir = [file stringByDeletingLastPathComponent];
    
    NSArray *filesOfDir = [[[NSFileManager defaultManager]contentsOfDirectoryAtPath:currentDir error:nil]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSMutableArray *audioFiles = [NSMutableArray array];
    
    for (NSString *object in filesOfDir) {
        NSString *newObject = [currentDir stringByAppendingPathComponent:object];
        if ([MIMEUtils isAudioFile:newObject]) {
            [audioFiles addObject:newObject];
        }
    }
    
    int fileIndex = [audioFiles indexOfObject:file];
    [self.prevTrack setHidden:(fileIndex == 0)];
    [self.nxtTrack setHidden:(fileIndex == audioFiles.count-1)];

    NSError *playingError = nil;
    
    if (![file isEqualToString:ad.nowPlayingFile]) {
        [ad.audioPlayer stop];
        ad.audioPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:file] error:&playingError];
        [ad.audioPlayer setDelegate:ad];
    }

    NSArray *iA = [metadataRetriever getMetadataForFile:file];
    
    NSString *artist = [iA objectAtIndex:0];
    NSString *title = [iA objectAtIndex:1];
    NSString *album = [iA objectAtIndex:2];
    
    NSString *metadata = [NSString stringWithFormat:@"%@\n%@\n%@",artist,title,album];
    
    if ([artist isEqualToString:@"---"] && [title isEqualToString:@"---"] && [album isEqualToString:@"---"]) {
        [ad showMetadataInLockscreenWithArtist:@"" title:[file lastPathComponent] album:@""];
    } else {
        [ad showMetadataInLockscreenWithArtist:artist title:title album:album];
    }
    
    [self.infoField setText:metadata];
    
    [ad showArtworkForFile:file];
    
    [self hideControls:(playingError != nil)];
    
    [ad.audioPlayer play];
    [ad setNowPlayingFile:file];
    
    if (!playingError) {
        [self startUpdatingTime];
    }
    
    NSString *loopContents = [NSString stringWithContentsOfFile:[kLibDir stringByAppendingPathComponent:@"loop.txt"] encoding:NSUTF8StringEncoding error:nil];
    [self setLoopOn:[loopContents isEqualToString:@"loop"]];
}

- (void)saveLoopState {
    self.isLooped = (_loopControl.currentMode == ToggleControlModeOn);
    [[kAppDelegate audioPlayer]setNumberOfLoops:self.isLooped?-1:0];
    [self.isLooped?@"loop":@"dloop" writeToFile:[kLibDir stringByAppendingPathComponent:@"loop.txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (void)setLoopOn:(BOOL)on {
    [kAppDelegate audioPlayer].numberOfLoops = on?-1:0;
    self.isLooped = on;
    [_loopControl setCurrentMode:on?ToggleControlModeOn:ToggleControlModeOff];
}

- (void)startConverting {
    
    AppDelegate *ad = kAppDelegate;
    
    NSString *fileName = [ad.openFile lastPathComponent];
    
    if (fileName.length > 14) {
        fileName = [[fileName substringToIndex:11]stringByAppendingString:@"..."];
    }
    
    [[BGProcFactory sharedFactory]startProcForKey:@"audio" andExpirationHandler:nil];

    [ad showHUDWithTitle:@"Converting"];
    [ad setSecondaryTitleOfVisibleHUD:fileName];
    [ad setVisibleHudMode:MBProgressHUDModeDeterminate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        @autoreleasepool {
        
            NSError *error = [AudioConverter convertAudioFileAtPath:ad.openFile progressObject:[ad getVisibleHUD]];
            
            [[BGProcFactory sharedFactory]endProcForKey:@"audio"];
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                
                @autoreleasepool {
                
                    [ad hideHUD];
                    
                    if (error) {
                        [TransparentAlert showAlertWithTitle:@"Conversion Error" andMessage:@"Swift could not convert the desired audio file."];
                    } else {
                     //   UIImageView *checkmark = [[[UIImageView alloc]initWithImage:getCheckmarkImage()]autorelease];
                        [ad showHUDWithTitle:@"Complete"];
                        [ad setSecondaryTitleOfVisibleHUD:fileName];
                        [ad setVisibleHudMode:MBProgressHUDModeCustomView];
//              /  [ad setVisibleHudCustomView:checkmark];
                        [ad hideVisibleHudAfterDelay:1.5];
                    }
                }
            });
        }
    });
}

- (void)hideControls:(BOOL)hide {
    [self.time setHidden:hide];
    [self.pausePlay setHidden:hide];
    [self.secondsRemaining setHidden:hide];
    [self.secondsDisplay setHidden:hide];
    [self.loopControl setHidden:hide];
    [self.stopButton setHidden:hide];
    [self.infoField setHidden:hide];
    [self.errorLabel setHidden:!hide];
}

- (void)setLoops {
    [[kAppDelegate audioPlayer]setNumberOfLoops:self.isLooped?-1:0];
    [self.isLooped?@"loop":@"dloop" writeToFile:[kLibDir stringByAppendingPathComponent:@"loop.txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (void)close {
    
    AppDelegate *ad = kAppDelegate;
    
    if (!ad.audioPlayer.isPlaying) {
        [ad.audioPlayer stop];
        [ad setAudioPlayer:nil];
        [ad setNowPlayingFile:nil];
    }
    
    [self stopUpdatingTime];
    
    [ad setOpenFile:nil];
    [self dismissModalViewControllerAnimated:YES];
}

- (NSString *)theTimeDisplay {
    int theTime = [[kAppDelegate audioPlayer]currentTime];
    int divBy60 = floor((theTime/60)+0.5);
    int timeWithoutMinutes = abs(theTime-(divBy60*60));
    return (timeWithoutMinutes < 10)?[NSString stringWithFormat:@"%d:0%d",divBy60,timeWithoutMinutes]:[NSString stringWithFormat:@"%d:%d",divBy60,timeWithoutMinutes];
}

- (void)startUpdatingTime {
    
    self.shouldStopCounter = NO;
    
    if (self.isGoing) {
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            while (!self.shouldStopCounter) {
                [NSThread sleepForTimeInterval:0.1f];
                dispatch_sync(dispatch_get_main_queue(), ^{
                    @autoreleasepool {
                        self.isGoing = YES;
                        [self updateTime];
                    }
                });
            }
            self.isGoing = NO;
        }
    });
}

- (void)stopUpdatingTime {
    self.shouldStopCounter = YES;
}

- (void)updateTime {
    [self.pausePlay setImage:[UIImage imageNamed:[[kAppDelegate audioPlayer]isPlaying]?@"pause":@"play"] forState:UIControlStateNormal];
    [self.pausePlay setImage:[UIImage imageNamed:[[kAppDelegate audioPlayer]isPlaying]?@"pause_pressed":@"play_pressed"] forState:UIControlStateHighlighted];
    self.time.value = [[kAppDelegate audioPlayer]currentTime]/[[kAppDelegate audioPlayer]duration];
    [self.secondsDisplay setText:[self theTimeDisplay]];
}

- (void)showActionSheet:(id)sender {
    
    if (self.popupQuery && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.popupQuery dismissWithClickedButtonIndex:self.popupQuery.cancelButtonIndex animated:YES];
        self.popupQuery = nil;
        return;
    }
        
    NSString *file = [kAppDelegate openFile];
        
    self.popupQuery = [[UIActionSheet alloc]initWithTitle:[NSString stringWithFormat:@"What would you like to do with %@?",[file lastPathComponent]] completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
        if (buttonIndex == 0) {
            [kAppDelegate sendFileInEmail:file fromViewController:self];
        } else if (buttonIndex == 1) {
            [kAppDelegate prepareFileForBTSending:file];
        } else if (buttonIndex == 2) {
            [kAppDelegate uploadLocalFile:[kAppDelegate openFile] fromViewController:self];
        } else if (buttonIndex == 3) {
            [self startConverting];
        }
    } cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Email File", @"Send Via Bluetooth", @"Upload to Dropbox", @"Convert to AAC", nil];
    
    self.popupQuery.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.popupQuery showFromBarButtonItem:(UIBarButtonItem *)sender animated:YES];
    } else {
        [self.popupQuery showInView:self.view];
    }
}

- (void)sliderChanged {
    [self.secondsDisplay setText:[self theTimeDisplay]];
    [[kAppDelegate audioPlayer]setCurrentTime:self.time.value*[[kAppDelegate audioPlayer]duration]];
}

- (void)togglePaused {
    [self startUpdatingTime];
    if ([[kAppDelegate audioPlayer]isPlaying]) {
        [[kAppDelegate audioPlayer]pause];
        [self.pausePlay setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
        [self.pausePlay setImage:[UIImage imageNamed:@"play_pressed"] forState:UIControlStateHighlighted];
    } else {
        [[kAppDelegate audioPlayer]play];
        [self.pausePlay setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
        [self.pausePlay setImage:[UIImage imageNamed:@"pause_pressed"] forState:UIControlStateHighlighted];
        [kAppDelegate setNowPlayingFile:[kAppDelegate openFile]];
    }
}

//
// NSNotifications
//

- (void)setPausePlayTitlePlay {
    [self.pausePlay setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
    [self.pausePlay setImage:[UIImage imageNamed:@"play_pressed"] forState:UIControlStateHighlighted];
}

- (void)setPausePlayTitlePause {
    [self.pausePlay setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
    [self.pausePlay setImage:[UIImage imageNamed:@"pause_pressed"] forState:UIControlStateHighlighted];
}

- (void)setLoopNotif {
    NSString *loopContents = [NSString stringWithContentsOfFile:[kLibDir stringByAppendingPathComponent:@"loop.txt"] encoding:NSUTF8StringEncoding error:nil];
    [self setLoopOn:[loopContents isEqualToString:@"loop"]];
}

- (void)hideControlsString:(NSNotification *)notif {
    if ([notif.object isEqualToString:@"YES"]) {
        [self hideControls:YES];
    } else {
        [self hideControls:NO];
    }
}

- (void)setNxtTrackHidden:(NSNotification *)notif {
    [self.nxtTrack setHidden:[notif.object isEqualToString:@"YES"]];
}

- (void)setPrevTrackHidden:(NSNotification *)notif {
    [self.prevTrack setHidden:[notif.object isEqualToString:@"YES"]];
}

- (void)setInfoFieldText:(NSNotification *)notif {
    [self.infoField setText:(NSString *)notif.object];
}

- (void)setSongTitleText:(NSNotification *)notif {
    self.navBar.topItem.title = notif.object;
}

- (void)setupNotifs {
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(setPausePlayTitlePlay) name:@"setPausePlayTitlePlay" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(setPausePlayTitlePause) name:@"setPausePlayTitlePause" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(setLoopNotif) name:@"setLoopNotif" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(hideControlsString:) name:@"hideControlsString:" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(setNxtTrackHidden:) name:@"setNxtTrackHidden:" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(setPrevTrackHidden:) name:@"setPrevTrackHidden:" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(setInfoFieldText:) name:@"setInfoFieldText:" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(setSongTitleText:) name:@"setSongTitleText:" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(startUpdatingTime) name:@"updTime1" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(stopUpdatingTime) name:@"updTime2" object:nil];
}

+ (void)notif_setPausePlayTitlePlay {
    [[NSNotificationCenter defaultCenter]postNotificationName:@"setPausePlayTitlePlay" object:nil];
}

+ (void)notif_setPausePlayTitlePause {
    [[NSNotificationCenter defaultCenter]postNotificationName:@"setPausePlayTitlePause" object:nil];
}

+ (void)notif_setLoop {
    [[NSNotificationCenter defaultCenter]postNotificationName:@"setLoopNotif" object:nil];
}

+ (void)notif_setControlsHidden:(BOOL)flag {
    if (flag) {
        [[NSNotificationCenter defaultCenter]postNotificationName:@"hideControlsString:" object:@"YES"];
    } else {
        [[NSNotificationCenter defaultCenter]postNotificationName:@"hideControlsString:" object:@"NO"];
    }
}

+ (void)notif_setNxtTrackHidden:(BOOL)flag {
    if (flag) {
        [[NSNotificationCenter defaultCenter]postNotificationName:@"setNxtTrackHidden:" object:@"YES"];
    } else {
        [[NSNotificationCenter defaultCenter]postNotificationName:@"setNxtTrackHidden:" object:@"NO"];
    }
}

+ (void)notif_setPrevTrackHidden:(BOOL)flag {
    if (flag) {
        [[NSNotificationCenter defaultCenter]postNotificationName:@"setPrevTrackHidden:" object:@"YES"];
    } else {
        [[NSNotificationCenter defaultCenter]postNotificationName:@"setPrevTrackHidden:" object:@"NO"];
    }
}

+ (void)notif_setInfoFieldText:(NSString *)string {
    [[NSNotificationCenter defaultCenter]postNotificationName:@"setInfoFieldText:" object:string];
}

+ (void)notif_setSongTitleText:(NSString *)string {
    [[NSNotificationCenter defaultCenter]postNotificationName:@"setSongTitleText:" object:string];
}

+ (void)notif_setShouldUpdateTime:(BOOL)flag {
    if (flag) {
        [[NSNotificationCenter defaultCenter]postNotificationName:@"updTime1" object:nil];
    } else {
        [[NSNotificationCenter defaultCenter]postNotificationName:@"updTime2" object:nil];
    }
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
