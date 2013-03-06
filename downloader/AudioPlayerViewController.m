//
//  AudioPlayerViewController.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 8/11/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import "AudioPlayerViewController.h"

@implementation AudioPlayerViewController

@synthesize prevTrack, nxtTrack, secondsRemaining, stopButton, errorLabel, control, pausePlay, time, secondsDisplay, infoField, popupQuery;

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
    [self.prevTrack addTarget:mainVC action:@selector(skipToPreviousTrack) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.prevTrack];
    
    self.nxtTrack = [[[BackAndForwardButton alloc]initWithFrame:iPad?CGRectMake(599, 533, 142, 51):CGRectMake(228, sanitizeMesurement(299), 72, 37)]autorelease];
    [self.nxtTrack setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"nexttrack" ofType:@"png"]] forState:UIControlStateNormal];
    [self.nxtTrack addTarget:mainVC action:@selector(skipToNextTrack) forControlEvents:UIControlEventTouchUpInside];
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
    
    if (![file isEqualToString:[kAppDelegate nowPlayingFile]]) {
        NSURL *url = [NSURL fileURLWithPath:file];
        AVAudioPlayer *ap = [[AVAudioPlayer alloc]initWithContentsOfURL:url error:&playingError];
        [_audioPlayer stop];
        [mainVC setAudioPlayer:ap];
        [ap release];
        [_audioPlayer setDelegate:mainVC];
    }

    NSArray *iA = [metadataRetriever getMetadataForFile:file];
    NSString *metadata = [NSString stringWithFormat:@"%@\n%@\n%@",[iA objectAtIndex:0],[iA objectAtIndex:1],[iA objectAtIndex:2]];
    
    [mainVC showMetadataInLockscreenWithArtist:[iA objectAtIndex:0] title:[iA objectAtIndex:1] album:[iA objectAtIndex:2]];
    [self.infoField setText:metadata];
    
    [mainVC showArtworkForFile:file];
    
    NSString *savedLoop = [kLibDir stringByAppendingPathComponent:@"loop.txt"];
    NSString *loopContents = [NSString stringWithContentsOfFile:savedLoop encoding:NSUTF8StringEncoding error:nil];
    
    if ([loopContents isEqualToString:@"loop"]) {
        [_audioPlayer setNumberOfLoops:-1];
        [self.control setSelectedSegmentIndex:0];
    } else {
        [_audioPlayer setNumberOfLoops:0];
        [self.control setSelectedSegmentIndex:1];
    }
    
    if (!playingError) {
        [self hideControls:YES];
        if (_audioPlayer) {
            [_audioPlayer play];
            [kAppDelegate setNowPlayingFile:file];
        }
    } else {
        [self.infoField setText:@""];
        [self hideControls:NO];
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
                CustomAlertView *av = [[CustomAlertView alloc]initWithTitle:@"Failed to Convert Audio File" message:@"Could not convert selected audio file" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [av show];
                [av release];
            } else {
                UIImageView *checkmark = [[UIImageView alloc]initWithImage:getCheckmarkImage()];
                
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
    if (hide) {
        [self.time setHidden:NO];
        [self.pausePlay setHidden:NO];
        [self.secondsRemaining setHidden:NO];
        [self.control setHidden:NO];
        [self.errorLabel setHidden:YES];
        [self.secondsRemaining setHidden:NO];
        [self.stopButton setHidden:NO];
        [self.time setEnabled:YES];
        [self.pausePlay setEnabled:YES];
        [self.stopButton setEnabled:YES];
    } else {
        [self.time setHidden:YES];
        [self.pausePlay setHidden:YES];
        [self.secondsDisplay setHidden:YES];
        [self.control setHidden:YES];
        [self.errorLabel setHidden:NO];
        [self.secondsRemaining setHidden:YES];
        [self.stopButton setHidden:YES];
        [self.time setEnabled:NO];
        [self.pausePlay setEnabled:NO];
        [self.stopButton setEnabled:NO];
    }
}

- (void)nextTrack {
    [mainVC skipToNextTrack];
}

- (void)setLoops {
    NSString *savedLoop = [kLibDir stringByAppendingPathComponent:@"loop.txt"];
    if (self.control.selectedSegmentIndex == 0 ) {
        [_audioPlayer setNumberOfLoops:-1];
        [@"loop" writeToFile:savedLoop atomically:YES encoding:NSUTF8StringEncoding error:nil];
    } else {
        [_audioPlayer setNumberOfLoops:0];
        [@"dontLoop" writeToFile:savedLoop atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}

- (void)close {
    if (![kAppDelegate nowPlayingFile]) {
        [_audioPlayer stop];
        [mainVC setAudioPlayer:nil];
    }
    
    [self stopUpdatingTime];
    
    [kAppDelegate setOpenFile:nil];
    [self dismissModalViewControllerAnimated:YES];
}

- (NSString *)theTimeDisplay {
    int theTime = [_audioPlayer currentTime];
    float divBy60Float = theTime/60;
    NSString *roundedInStringFormat = [NSString stringWithFormat:@"%.0f",divBy60Float];
    int divBy60 = [roundedInStringFormat intValue];
    int timeWithoutMinutes = theTime-(divBy60*60);
    int lol = abs(timeWithoutMinutes);
    
    if (lol < 10) {
        return [NSString stringWithFormat:@"%d:0%d",divBy60,lol];
    } else {
        return [NSString stringWithFormat:@"%d:%d",divBy60,lol];
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
    
    if ([_audioPlayer isPlaying]) {
        self.time.value = [_audioPlayer currentTime]/[_audioPlayer duration];
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
    [_audioPlayer setCurrentTime:self.time.value*[_audioPlayer duration]];
}

- (void)togglePause {
    if ([_audioPlayer isPlaying]) {
        [_audioPlayer pause];
        [self.pausePlay setTitle:@"Play" forState:UIControlStateNormal];
        [self stopUpdatingTime];
    } else {
        [_audioPlayer play];
        [self.pausePlay setTitle:@"Pause" forState:UIControlStateNormal];
        [kAppDelegate setNowPlayingFile:[kAppDelegate openFile]];
        [self startUpdatingTime];
    }
}

- (void)stopAudio {
    [self stopUpdatingTime];
    [_audioPlayer stop];
    [_audioPlayer setCurrentTime:0.0f];
    [self.time setValue:0.0f];
    [self.secondsDisplay setText:@"0:00"];
    [kAppDelegate setNowPlayingFile:nil];
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
        [self.infoField setText:@""];
    }
}

- (void)setNxtTrackHidden:(NSNotification *)notif {
    if ([notif.object isEqualToString:@"YES"]) {
        [self.nxtTrack setHidden:YES];
    } else {
        [self.nxtTrack setHidden:NO];
    }
}

- (void)setPrevTrackHidden:(NSNotification *)notif {
    if ([notif.object isEqualToString:@"YES"]) {
        [self.prevTrack setHidden:YES];
    } else {
        [self.prevTrack setHidden:NO];
    }
}

- (void)setInfoFieldText:(NSNotification *)notif {
    [self.infoField setText:notif.object];
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
