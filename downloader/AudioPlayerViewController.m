//
//  AudioPlayerViewController.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 8/11/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import "AudioPlayerViewController.h"

@implementation AudioPlayerViewController

@synthesize prevTrack, nxtTrack, secondsRemaining, stopButton, errorLabel, control, pausePlay, time, secondsDisplay, infoField, popupQuery, shouldStopPlayingAudio;

- (void)loadView {
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    
    self.view = [[[UIView alloc]initWithFrame:screenBounds]autorelease];
    self.view.backgroundColor = [UIColor clearColor];
    
    self.navBar = [[[CustomNavBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)]autorelease];
    self.navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[[UINavigationItem alloc]initWithTitle:[[kAppDelegate openFile]lastPathComponent]]autorelease];
    topItem.rightBarButtonItem = [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showActionSheet:)]autorelease];
    topItem.leftBarButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)]autorelease];
    [self.navBar pushNavigationItem:topItem animated:YES];
    [self.view addSubview:self.navBar];
    [self.view bringSubviewToFront:self.navBar];
    
    BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    
    self.time = [[[CustomSlider alloc]initWithFrame:CGRectMake(5, iPad?357:sanitizeMesurement(219), screenBounds.size.width-10, 23)]autorelease];
    [self.time addTarget:self action:@selector(sliderChanged) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.time];
    
    self.prevTrack = [[[BackAndForwardButton alloc]initWithFrame:iPad?CGRectMake(20, 533, 142, 51):CGRectMake(20, sanitizeMesurement(299), 72, 37)]autorelease];
    [self.prevTrack setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"prevtrack" ofType:@"png"]] forState:UIControlStateNormal];
    [self.prevTrack addTarget:kAppDelegate action:@selector(skipToPreviousTrack) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.prevTrack];
    
    self.nxtTrack = [[[BackAndForwardButton alloc]initWithFrame:iPad?CGRectMake(599, 533, 142, 51):CGRectMake(228, sanitizeMesurement(299), 72, 37)]autorelease];
    [self.nxtTrack setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"nexttrack" ofType:@"png"]] forState:UIControlStateNormal];
    [self.nxtTrack addTarget:kAppDelegate action:@selector(skipToNextTrack) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.nxtTrack];
    
    self.pausePlay = [[[CustomButton alloc]initWithFrame:iPad?CGRectMake(323, 481, 142, 51):CGRectMake(124, sanitizeMesurement(266), 72, 37)]autorelease];
    [self.pausePlay setTitle:@"Pause" forState:UIControlStateNormal];
    self.pausePlay.titleLabel.font = [UIFont boldSystemFontOfSize:iPad?18:15];
    [self.pausePlay addTarget:self action:@selector(togglePause) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.pausePlay];
    
    self.stopButton = [[[CustomButton alloc]initWithFrame:iPad?CGRectMake(323, 589, 142, 51):CGRectMake(124, sanitizeMesurement(332), 72, 37)]autorelease];
    self.stopButton.titleLabel.font = [UIFont boldSystemFontOfSize:iPad?18:15];
    [self.stopButton setTitle:@"Stop" forState:UIControlStateNormal];
    [self.stopButton addTarget:self action:@selector(stopAudio) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:stopButton];
    
    self.infoField = [[[UITextView alloc]initWithFrame:CGRectMake(0, 44, screenBounds.size.width, sanitizeMesurement(65))]autorelease];
    self.infoField.textAlignment = UITextAlignmentCenter;
    self.infoField.textColor = [UIColor whiteColor];
    self.infoField.font = [UIFont boldSystemFontOfSize:15];
    self.infoField.editable = NO;
    self.infoField.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.infoField];
    
    self.control = [[[CustomSegmentedControl alloc]initWithFrame:iPad?CGRectMake(275, 163, 219, 44):CGRectMake(51, sanitizeMesurement(117), 219, 44)]autorelease];
    [self.control insertSegmentWithTitle:@"Loop" atIndex:0 animated:YES];
    [self.control insertSegmentWithTitle:@"Don't Loop" atIndex:1 animated:YES];
    [self.view addSubview:self.control];
    
    self.secondsRemaining = [[[UILabel alloc]initWithFrame:iPad?CGRectMake(315, 220, 139, 35):CGRectMake(51, sanitizeMesurement(187), 112, 21)]autorelease];
    self.secondsRemaining.text = @"Time Elapsed:";
    self.secondsRemaining.backgroundColor = [UIColor clearColor];
    self.secondsRemaining.textColor = [UIColor whiteColor];
    self.secondsRemaining.font = iPad?[UIFont boldSystemFontOfSize:20]:[UIFont systemFontOfSize:17];
    [self.view addSubview:self.secondsRemaining];
    
    self.secondsDisplay = [[[UILabel alloc]initWithFrame:iPad?CGRectMake(0, 263, 768, 55):CGRectMake(164, sanitizeMesurement(185), 136, 27)]autorelease];
    self.secondsDisplay.font = [UIFont boldSystemFontOfSize:iPad?39:24];
    self.secondsDisplay.textColor = [UIColor whiteColor];
    self.secondsDisplay.backgroundColor = [UIColor clearColor];
    self.secondsDisplay.text = @"0:00";
    [self.view addSubview:self.secondsDisplay];
    
    self.errorLabel = [[[UILabel alloc]initWithFrame:iPad?CGRectMake(14, 311, 727, 113):CGRectMake(4, sanitizeMesurement(149), 313, 57)]autorelease];
    self.errorLabel.text = @"Error Playing Audio";
    self.errorLabel.backgroundColor = [UIColor clearColor];
    self.errorLabel.textColor = [UIColor whiteColor];
    self.errorLabel.font = [UIFont boldSystemFontOfSize:iPad?72:33];
    [self.view addSubview:self.errorLabel];
    
    CustomToolbar *toolBar = [[[CustomToolbar alloc]initWithFrame:CGRectMake(0, screenBounds.size.height-44, screenBounds.size.width, 44)]autorelease];
    
    MPVolumeView *volView = [[[MPVolumeView alloc]initWithFrame:CGRectMake(0, 12, screenBounds.size.width-25, 20)]autorelease];
    
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
    
    UIBarButtonItem *volume = [[[UIBarButtonItem alloc]initWithCustomView:volView]autorelease];
    
    toolBar.items = [NSArray arrayWithObjects:volume, nil];
    [self.view addSubview:toolBar];
    [self.view bringSubviewToFront:toolBar];
    
    [self setupNotifs];
    NSString *file = [kAppDelegate openFile];
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
    
    if (fileIndex == 0) {
        [self.prevTrack setHidden:YES];
    }
    
    if (fileIndex == audioFiles.count-1) {
        [self.nxtTrack setHidden:YES];
    }

    NSError *playingError = nil;
    
    downloaderAppDelegate *ad = kAppDelegate;
    
    if (![file isEqualToString:[kAppDelegate nowPlayingFile]]) {
        [ad.audioPlayer stop];
        ad.audioPlayer = [[[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:file] error:&playingError]autorelease];
        [ad.audioPlayer setDelegate:ad];
    }

    NSArray *iA = [metadataRetriever getMetadataForFile:file];
    NSString *metadata = [NSString stringWithFormat:@"%@\n%@\n%@",[iA objectAtIndex:0],[iA objectAtIndex:1],[iA objectAtIndex:2]];
    
    [ad showMetadataInLockscreenWithArtist:[iA objectAtIndex:0] title:[iA objectAtIndex:1] album:[iA objectAtIndex:2]];
    [self.infoField setText:metadata];
    
    [ad showArtworkForFile:file];
    
    NSString *savedLoop = [kLibDir stringByAppendingPathComponent:@"loop.txt"];
    NSString *loopContents = [NSString stringWithContentsOfFile:savedLoop encoding:NSUTF8StringEncoding error:nil];
    
    if ([loopContents isEqualToString:@"loop"]) {
        [ad.audioPlayer setNumberOfLoops:-1];
        [self.control setSelectedSegmentIndex:0];
    } else {
        [ad.audioPlayer setNumberOfLoops:0];
        [self.control setSelectedSegmentIndex:1];
    }
    
    if (!playingError) {
        [self hideControls:NO];
        if (ad.audioPlayer) {
            [ad.audioPlayer play];
            [ad setNowPlayingFile:file];
            self.shouldStopPlayingAudio = NO;
        }
    } else {
        [self hideControls:YES];
    }
    [self startUpdatingTime];
}

- (void)startConverting {
    
    NSString *fileName = [[kAppDelegate openFile]lastPathComponent];
    
    if (fileName.length > 14) {
        NSString *fnZZ = [fileName substringToIndex:14];
        fileName = [fnZZ stringByAppendingString:@"..."];
    }

    downloaderAppDelegate *ad = kAppDelegate;
    [ad showHUDWithTitle:@"Converting"];
    [ad setSecondaryTitleOfVisibleHUD:fileName];
    [ad setVisibleHudMode:MBProgressHUDModeDeterminate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
        
        NSError *error = [AudioConverter convertAudioFileAtPath:ad.openFile progressObject:[ad getVisibleHUD]];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            NSAutoreleasePool *poolTwo = [[NSAutoreleasePool alloc]init];
            
            [ad hideHUD];
            
            if (error) {
                CustomAlertView *av = [[CustomAlertView alloc]initWithTitle:@"Conversion Error" message:@"SwiftLoad could not convert the desired audio file." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [av show];
                [av release];
            } else {
                UIImageView *checkmark = [[[UIImageView alloc]initWithImage:getCheckmarkImage()]autorelease];
                [ad showHUDWithTitle:@"Complete"];
                [ad setSecondaryTitleOfVisibleHUD:fileName];
                [ad setVisibleHudMode:MBProgressHUDModeCustomView];
                [ad setVisibleHudCustomView:checkmark];
                [ad hideVisibleHudAfterDelay:1.5];
            }
            [poolTwo release];
        });
        [pool release];
    });
}

- (void)uploadToDropbox {
    if ([[DBSession sharedSession]isLinked]) {
        [kAppDelegate uploadLocalFile:[kAppDelegate openFile]];
    } else {
        [[DBSession sharedSession]linkFromController:self];
    }
}

- (void)hideControls:(BOOL)hide {
    [self.time setHidden:hide];
    [self.pausePlay setHidden:hide];
    [self.secondsRemaining setHidden:hide];
    [self.secondsDisplay setHidden:hide];
    [self.control setHidden:hide];
    [self.stopButton setHidden:hide];
    [self.infoField setHidden:hide];
    [self.errorLabel setHidden:!hide];
}

- (void)setLoops {
    NSString *savedLoop = [kLibDir stringByAppendingPathComponent:@"loop.txt"];
    if (self.control.selectedSegmentIndex == 0 ) {
        [[kAppDelegate audioPlayer]setNumberOfLoops:-1];
        [@"loop" writeToFile:savedLoop atomically:YES encoding:NSUTF8StringEncoding error:nil];
    } else {
        [[kAppDelegate audioPlayer]setNumberOfLoops:0];
        [@"dontLoop" writeToFile:savedLoop atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}

- (void)close {
    if (self.shouldStopPlayingAudio) {
        [[kAppDelegate audioPlayer]stop];
        [kAppDelegate setAudioPlayer:nil];
        [kAppDelegate setNowPlayingFile:nil];
    }
    
    [self stopUpdatingTime];
    
    [kAppDelegate setOpenFile:nil];
    [self dismissModalViewControllerAnimated:YES];
}

- (NSString *)theTimeDisplay {
    int theTime = [[kAppDelegate audioPlayer]currentTime];
    int divBy60 = floor((theTime/60)+0.5);
    int timeWithoutMinutes = abs(theTime-(divBy60*60));
    
    if (timeWithoutMinutes < 10) {
        return [NSString stringWithFormat:@"%d:0%d",divBy60,timeWithoutMinutes];
    } else {
        return [NSString stringWithFormat:@"%d:%d",divBy60,timeWithoutMinutes];
    }
}

- (void)startUpdatingTime {
    
    shouldStopCounter = NO;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
        
        while (!shouldStopCounter) {
            [NSThread sleepForTimeInterval:0.1f];
            dispatch_sync(dispatch_get_main_queue(), ^{
                NSAutoreleasePool *poolTwo = [[NSAutoreleasePool alloc]init];
                [self updateTime];
                [poolTwo release];
            });
        }
        [pool release];
    });
}

- (void)stopUpdatingTime {
    shouldStopCounter = YES;
}

- (void)updateTime {
    
    if ([[kAppDelegate audioPlayer]isPlaying]) {
        self.time.value = [[kAppDelegate audioPlayer]currentTime]/[[kAppDelegate audioPlayer]duration];
        [self.secondsDisplay setText:[self theTimeDisplay]];
        [self.pausePlay setTitle:@"Pause" forState:UIControlStateNormal];
    } else {
        [self.pausePlay setTitle:@"Play" forState:UIControlStateNormal];
    }
}

- (void)showActionSheet:(id)sender {
        
    NSString *file = [kAppDelegate openFile];
        
    self.popupQuery = [[UIActionSheet alloc]initWithTitle:[NSString stringWithFormat:@"What would you like to do with %@?",[file lastPathComponent]] completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
        if (buttonIndex == 0) {
            [kAppDelegate sendFileInEmail:file fromViewController:self];
        } else if (buttonIndex == 1) {
            [kAppDelegate showBTController];
        } else if (buttonIndex == 2) {
            [kAppDelegate showFTPUploadController];
        } else if (buttonIndex == 3) {
            [self uploadToDropbox];
        } else if (buttonIndex == 4) {
            [self startConverting];
        }
    } cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Email File", @"Send Via Bluetooth", @"Upload to Server", @"Upload to Dropbox", @"Convert to AAC", nil];
    
    self.popupQuery.actionSheetStyle = UIActionSheetStyleBlackTranslucent;

    if (!self.popupQuery.isVisible) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            [self.popupQuery showFromBarButtonItem:(UIBarButtonItem *)sender animated:YES];
        } else {
            [self.popupQuery showInView:self.view];
        }
    } else {
        [self.popupQuery dismissWithClickedButtonIndex:[self.popupQuery cancelButtonIndex] animated:YES];
    }
}

- (void)sliderChanged {
    [[kAppDelegate audioPlayer]setCurrentTime:self.time.value*[[kAppDelegate audioPlayer]duration]];
}

- (void)togglePause {
    if ([[kAppDelegate audioPlayer]isPlaying]) {
        [[kAppDelegate audioPlayer]pause];
        [self.pausePlay setTitle:@"Play" forState:UIControlStateNormal];
        [self stopUpdatingTime];
    } else {
        [[kAppDelegate audioPlayer]play];
        [self.pausePlay setTitle:@"Pause" forState:UIControlStateNormal];
        [kAppDelegate setNowPlayingFile:[kAppDelegate openFile]];
        self.shouldStopPlayingAudio = NO;
        [self startUpdatingTime];
    }
}

- (void)stopAudio {
    [self stopUpdatingTime];
    [[kAppDelegate audioPlayer]stop];
    [[kAppDelegate audioPlayer]setCurrentTime:0.0f];
    [self.time setValue:0.0f];
    [self.secondsDisplay setText:@"0:00"];
    self.shouldStopPlayingAudio = YES;
    //[kAppDelegate setNowPlayingFile:nil];
}


//
// NSNotifications
//

- (void)setPausePlayTitlePlay {
    [self.pausePlay setTitle:@"Play" forState:UIControlStateNormal];
}

- (void)setPausePlayTitlePause {
    [self.pausePlay setTitle:@"Pause" forState:UIControlStateNormal];
}

- (void)setLoopNotif {
    NSString *loopContents = [NSString stringWithContentsOfFile:[kLibDir stringByAppendingPathComponent:@"loop.txt"] encoding:NSUTF8StringEncoding error:nil];
    
    if ([loopContents isEqualToString:@"loop"]) {
        [self.control setSelectedSegmentIndex:0];
    } else {
        [self.control setSelectedSegmentIndex:1];
    }
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

- (void)setStopPlayingAudioFileBool:(NSNotification *)notif {
    self.shouldStopPlayingAudio = notif.object;
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
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(setStopPlayingAudioFileBool:) name:@"stopPlayingAudio" object:nil];
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

+ (void)notif_setShouldStopPlayingAudio:(BOOL)flag {
    [[NSNotificationCenter defaultCenter]postNotificationName:@"stopPlayingAudio" object:flag?(id)kCFBooleanTrue:(id)kCFBooleanFalse];
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
    [self setPopupQuery:nil];
    [self setPrevTrack:nil];
    [self setNxtTrack:nil];
    [self setSecondsRemaining:nil];
    [self setStopButton:nil];
    [self setErrorLabel:nil];
    [self setControl:nil];
    [self setPausePlay:nil];
    [self setTime:nil];
    [self setSecondsDisplay:nil];
    [self setInfoField:nil];
    NSLog(@"%@ dealloc'd", NSStringFromClass([self class]));
    [super dealloc];
}

@end
