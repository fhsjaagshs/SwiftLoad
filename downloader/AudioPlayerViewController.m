//
//  AudioPlayerViewController.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 8/11/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import "AudioPlayerViewController.h"

@interface AudioPlayerViewController ()

//@property (nonatomic, strong) UILabel *secondsDisplay;
@property (nonatomic, strong) UILabel *errorLabel;
@property (nonatomic, strong) UILabel *secondsRemaining;
@property (nonatomic, strong) UILabel *secondsElapsed;

@property (nonatomic, strong) UIButton *pausePlay;
@property (nonatomic, strong) UIButton *stopButton;
@property (nonatomic, strong) UIButton *nxtTrack;
@property (nonatomic, strong) UIButton *prevTrack;

@property (nonatomic, strong) MarqueeLabel *artistLabel;
@property (nonatomic, strong) MarqueeLabel *titleLabel;
@property (nonatomic, strong) MarqueeLabel *albumLabel;

@property (nonatomic, strong) UISlider *time;
@property (nonatomic, strong) ShadowedNavBar *navBar;

@property (nonatomic, strong) ToggleControl *loopControl;

@property (nonatomic, strong) UIActionSheet *popupQuery;

@end

@implementation AudioPlayerViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [MarqueeLabel controllerViewAppearing:self];
}

- (void)loadView {
    [super loadView];
    
    [self setupNotifs];
    
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    
    self.navBar = [[ShadowedNavBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)];
    _navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:[[kAppDelegate openFile]lastPathComponent]];
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showActionSheet:)];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    [_navBar pushNavigationItem:topItem animated:YES];
    [self.view addSubview:_navBar];
    
    self.artistLabel = [[MarqueeLabel alloc]initWithFrame:CGRectMake(0, 44+10, screenBounds.size.width, 20) duration:5.0 andFadeLength:10.0f];
    _artistLabel.animationDelay = 0.5f;
    _artistLabel.marqueeType = MLContinuous;
    _artistLabel.animationCurve = UIViewAnimationCurveLinear;
    _artistLabel.numberOfLines = 1;
    _artistLabel.textAlignment = UITextAlignmentCenter;
    _artistLabel.backgroundColor = [UIColor clearColor];
    _artistLabel.textColor = [UIColor blackColor];
    _artistLabel.font = [UIFont systemFontOfSize:15];
    [self.view addSubview:_artistLabel];
    
    self.titleLabel = [[MarqueeLabel alloc]initWithFrame:CGRectMake(0, 44+20+10, screenBounds.size.width, 20) rate:50.0f andFadeLength:10.0f];
    _titleLabel.animationDelay = 0.5f;
    _titleLabel.marqueeType = MLContinuous;
    _titleLabel.animationCurve = UIViewAnimationCurveLinear;
    _titleLabel.numberOfLines = 1;
    _titleLabel.textAlignment = UITextAlignmentCenter;
    _titleLabel.backgroundColor = [UIColor clearColor];
    _titleLabel.textColor = [UIColor blackColor];
    _titleLabel.font = [UIFont boldSystemFontOfSize:15];
    [self.view addSubview:_titleLabel];
    
    self.albumLabel = [[MarqueeLabel alloc]initWithFrame:CGRectMake(0, 44+(20*2)+10, screenBounds.size.width, 20) duration:5.0 andFadeLength:10.0f];
    _albumLabel.animationDelay = 0.5f;
    _albumLabel.marqueeType = MLContinuous;
    _albumLabel.animationCurve = UIViewAnimationCurveLinear;
    _albumLabel.numberOfLines = 1;
    _albumLabel.textAlignment = UITextAlignmentCenter;
    _albumLabel.backgroundColor = [UIColor clearColor];
    _albumLabel.textColor = [UIColor blackColor];
    _albumLabel.font = [UIFont systemFontOfSize:15];
    [self.view addSubview:_albumLabel];
    
    self.secondsElapsed = [[UILabel alloc]initWithFrame:CGRectMake(0, 114+10, 44, 23)];
    _secondsElapsed.font = [UIFont boldSystemFontOfSize:15];
    _secondsElapsed.textColor = [UIColor blackColor];
    _secondsElapsed.backgroundColor = [UIColor clearColor];
    _secondsElapsed.textAlignment = UITextAlignmentRight;
    _secondsElapsed.text = @"0:00";
    [self.view addSubview:_secondsElapsed];
    
    self.time = [[UISlider alloc]initWithFrame:CGRectMake(44, 114+10, screenBounds.size.width-88, 23)];
    [_time setMinimumTrackTintColor:[UIColor colorWithRed:21.0f/255.0f green:92.0f/255.0f blue:136.0f/255.0f alpha:1.0f]];
    [_time setMaximumTrackTintColor:[UIColor colorWithRed:105.0f/255.0f green:179.0f/255.0f blue:216.0f/255.0f alpha:1.0f]];
    [_time addTarget:self action:@selector(sliderChanged) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_time];
    
    self.secondsRemaining = [[UILabel alloc]initWithFrame:CGRectMake(screenBounds.size.width-44, 114+10, 44, 23)];
    _secondsRemaining.font = [UIFont boldSystemFontOfSize:15];
    _secondsRemaining.textColor = [UIColor blackColor];
    _secondsRemaining.backgroundColor = [UIColor clearColor];
    _secondsRemaining.textAlignment = UITextAlignmentLeft;
    _secondsRemaining.text = @"-0:00";
    [self.view addSubview:_secondsRemaining];
    
    self.prevTrack = [[UIButton alloc]initWithFrame:CGRectMake(20, screenBounds.size.height-44-46-10, iPad?62:48.5, iPad?46:36)];
    _prevTrack.backgroundColor = [UIColor clearColor];
    [_prevTrack setImage:[UIImage imageNamed:@"back_button"] forState:UIControlStateNormal];
    [_prevTrack setImage:[UIImage imageNamed:@"back_button_pressed"] forState:UIControlStateHighlighted];
    [_prevTrack addTarget:kAppDelegate action:@selector(skipToPreviousTrack) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_prevTrack];
    
    self.nxtTrack = [[UIButton alloc]initWithFrame:CGRectMake(screenBounds.size.width-(iPad?62:48.5)-20, screenBounds.size.height-44-46-10, iPad?62:48.5, iPad?46:36)];
    _nxtTrack.backgroundColor = [UIColor clearColor];
    [_nxtTrack setImage:[UIImage imageNamed:@"next_button"] forState:UIControlStateNormal];
    [_nxtTrack setImage:[UIImage imageNamed:@"next_button_pressed"] forState:UIControlStateHighlighted];
    [_nxtTrack addTarget:kAppDelegate action:@selector(skipToNextTrack) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_nxtTrack];
    
    self.pausePlay = [[UIButton alloc]initWithFrame:CGRectMake((screenBounds.size.width/2)-((iPad?52:41)/2), screenBounds.size.height-44-46-10, iPad?52:41, iPad?46:36)];
    _pausePlay.backgroundColor = [UIColor clearColor];
    [_pausePlay setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
    [_pausePlay setImage:[UIImage imageNamed:@"pause_selected"] forState:UIControlStateHighlighted];
    [_pausePlay addTarget:kAppDelegate action:@selector(togglePlayPause) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_pausePlay];
    
    self.errorLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 44, screenBounds.size.width, screenBounds.size.height-88)];
    _errorLabel.text = @"Error Playing Audio";
    _errorLabel.backgroundColor = [UIColor clearColor];
    _errorLabel.textColor = [UIColor blackColor];
    _errorLabel.font = [UIFont boldSystemFontOfSize:iPad?72:33];
    [self.view addSubview:_errorLabel];
    [_errorLabel setHidden:YES];
    
    UIToolbar *toolBar = [[ShadowedToolbar alloc]initWithFrame:CGRectMake(0, screenBounds.size.height-44, screenBounds.size.width, 44)];
    toolBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    
    MPVolumeView *volView = [[MPVolumeView alloc]initWithFrame:CGRectMake(0, 12, screenBounds.size.width-70, 20)];
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
    
    self.loopControl = [[ToggleControl alloc]initWithFrame:CGRectMake(0, 0, 30, 30)];
    _loopControl.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [_loopControl addTarget:self action:@selector(saveLoopState) forControlEvents:UIControlEventTouchUpInside];
    _loopControl.backgroundColor = [UIColor clearColor];
    [_loopControl setImage:[UIImage imageNamed:@"loop_on"] forState:ToggleControlModeOn];
    [_loopControl setImage:[UIImage imageNamed:@"loop_off"] forState:ToggleControlModeOff];
    [_loopControl setImage:[UIImage imageNamed:@"loop_pressed"] forState:ToggleControlModeIntermediate];
    
    UIBarButtonItem *volume = [[UIBarButtonItem alloc]initWithCustomView:volView];
    UIBarButtonItem *loopControl = [[UIBarButtonItem alloc]initWithCustomView:_loopControl];

    toolBar.items = @[loopControl, volume];
    [self.view addSubview:toolBar];
    [self.view bringSubviewToFront:toolBar];
    
    [kAppDelegate playFile:[kAppDelegate openFile]];
    
    [self refreshLoopState];
    [MarqueeLabel controllerLabelsShouldAnimate:self];
}

- (void)saveLoopState {
    [[NSUserDefaults standardUserDefaults]setBool:(_loopControl.currentMode == ToggleControlModeOn) forKey:@"loop"];
}

- (void)setLoopState:(BOOL)on {
    [[NSUserDefaults standardUserDefaults]setBool:on forKey:@"loop"];
}

- (void)refreshLoopState {
    BOOL on = [[NSUserDefaults standardUserDefaults]boolForKey:@"loop"];
    [kAppDelegate audioPlayer].numberOfLoops = on?-1:0;
    self.isLooped = on;
    [_loopControl setCurrentMode:on?ToggleControlModeOn:ToggleControlModeOff];
}

- (void)hideControls:(BOOL)hide {
    [_time setHidden:hide];
    [_pausePlay setHidden:hide];
    [_secondsRemaining setHidden:hide];
    [_secondsElapsed setHidden:hide];
    [_loopControl setHidden:hide];
    [_stopButton setHidden:hide];
    [_artistLabel setHidden:hide];
    [_titleLabel setHidden:hide];
    [_albumLabel setHidden:hide];
    [_errorLabel setHidden:!hide];
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

- (void)startUpdatingTime {
    
    self.shouldStopCounter = NO;
    
    if (_isGoing) {
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        @autoreleasepool {
            while (!_shouldStopCounter) {
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
    
    AppDelegate *ad = kAppDelegate;
    
    float currentTime = ad.audioPlayer.currentTime;
    
    if (currentTime < 0) {
        return;
    }
    
    float duration = ad.audioPlayer.duration;

    _time.value = currentTime/duration;

    int minutes = floor(currentTime/60);
    int seconds = abs(currentTime-(minutes*60));
    
    _secondsElapsed.text = [NSString stringWithFormat:@"%d:%@%d",minutes,((seconds < 10)?@"0":@""),seconds];
    
    int remainingTime = duration-((minutes*60)+seconds);
    int remainingMinutes = floor(remainingTime/60);
    int remainingSeconds = abs(remainingTime-(remainingMinutes*60));
    _secondsRemaining.text = [NSString stringWithFormat:@"-%d:%@%d",remainingMinutes,((remainingSeconds < 10)?@"0":@""),remainingSeconds];
    
}

- (void)showActionSheet:(id)sender {
    
    if (self.popupQuery && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.popupQuery dismissWithClickedButtonIndex:self.popupQuery.cancelButtonIndex animated:YES];
        self.popupQuery = nil;
        return;
    }
        
    NSString *file = [kAppDelegate openFile];
        
    self.popupQuery = [[UIActionSheet alloc]initWithTitle:[NSString stringWithFormat:@"What would you like to do with %@?",[file lastPathComponent]] completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {

        if (buttonIndex == _popupQuery.cancelButtonIndex) {
            return;
        }
        
        if (buttonIndex == 0) {
            [kAppDelegate sendFileInEmail:file];
        } else if (buttonIndex == 1) {
            BluetoothTask *task = [BluetoothTask taskWithFile:[kAppDelegate openFile]];
            [[TaskController sharedController]addTask:task];
        } else if (buttonIndex == 2) {
            DropboxUpload *task = [DropboxUpload uploadWithFile:[kAppDelegate openFile]];
            [[TaskController sharedController]addTask:task];
        } else if (buttonIndex == 3) {
            EditID3ViewController *controller = [EditID3ViewController viewControllerWhite];
            [self presentModalViewController:controller animated:YES];
        }
    } cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Email File", @"Send via Bluetooth", @"Upload to Dropbox", nil];
    
    self.popupQuery.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    
    NSLog(@"%@",file.pathExtension.lowercaseString);
    
    if (_errorLabel.hidden && [file.pathExtension.lowercaseString isEqualToString:@"mp3"]) {
        [_popupQuery addButtonWithTitle:@"Edit Metadata"];
    }
    
    [_popupQuery addButtonWithTitle:@"Cancel"];
    
    [_popupQuery setCancelButtonIndex:_popupQuery.numberOfButtons-1];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.popupQuery showFromBarButtonItem:(UIBarButtonItem *)sender animated:YES];
    } else {
        [self.popupQuery showInView:self.view];
    }
}

- (void)sliderChanged {
    AppDelegate *ad = kAppDelegate;
    
    float currentTime = ad.audioPlayer.currentTime;
    float duration = ad.audioPlayer.duration;
    
    int minutes = floor(currentTime/60);
    int seconds = abs(currentTime-(minutes*60));

    _secondsElapsed.text = [NSString stringWithFormat:@"%d:%@%d",minutes,((seconds < 10)?@"0":@""),seconds];
    
    int remainingTime = duration-((minutes*60)+seconds);
    int remainingMinutes = floor(remainingTime/60);
    int remainingSeconds = abs(remainingTime-(remainingMinutes*60));
    _secondsRemaining.text = [NSString stringWithFormat:@"-%d:%@%d",remainingMinutes,((remainingSeconds < 10)?@"0":@""),remainingSeconds];
    
    ad.audioPlayer.currentTime = _time.value*ad.audioPlayer.duration;
}

- (void)togglePaused {
    [self startUpdatingTime];
    
    AppDelegate *ad = kAppDelegate;
    
    if (ad.audioPlayer.isPlaying) {
        [ad.audioPlayer pause];
        [_pausePlay setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
        [_pausePlay setImage:[UIImage imageNamed:@"play_pressed"] forState:UIControlStateHighlighted];
    } else {
        [ad.audioPlayer play];
        [_pausePlay setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
        [_pausePlay setImage:[UIImage imageNamed:@"pause_pressed"] forState:UIControlStateHighlighted];
        [ad setNowPlayingFile:ad.openFile];
    }
}

//
// NSNotifications
//

- (void)setPausePlayTitlePlay {
    [_pausePlay setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
    [_pausePlay setImage:[UIImage imageNamed:@"play_pressed"] forState:UIControlStateHighlighted];
}

- (void)setPausePlayTitlePause {
    [_pausePlay setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
    [_pausePlay setImage:[UIImage imageNamed:@"pause_pressed"] forState:UIControlStateHighlighted];
}

- (void)setLoopNotif {
    [self refreshLoopState];
}

- (void)hideControlsString:(NSNotification *)notif {
    if ([notif.object isEqualToString:@"YES"]) {
        [self hideControls:YES];
    } else {
        [self hideControls:NO];
    }
}

- (void)setNxtTrackHidden:(NSNotification *)notif {
    _nxtTrack.hidden = [notif.object isEqualToString:@"YES"];
}

- (void)setPrevTrackHidden:(NSNotification *)notif {
    _prevTrack.hidden = [notif.object isEqualToString:@"YES"];
}

- (void)setInfoFieldText:(NSNotification *)notif {
    
    NSArray *components = [(NSString *)notif.object componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

    if (components.count > 0) {
        _artistLabel.text = (NSString *)[components objectAtIndex:0];
        _titleLabel.text = (NSString *)[components objectAtIndex:1];
        _albumLabel.text = (NSString *)[components objectAtIndex:2];
    }
}

- (void)setSongTitleText:(NSNotification *)notif {
    _navBar.topItem.title = notif.object;
}

- (void)setupNotifs {
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(setPausePlayTitlePlay) name:@"setPausePlayTitlePlay" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(setPausePlayTitlePause) name:@"setPausePlayTitlePause" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(setLoopNotif) name:@"setLoopNotif" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(hideControlsString:) name:@"hideControlsString:" object:nil];
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
