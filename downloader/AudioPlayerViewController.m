//
//  AudioPlayerViewController.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 8/11/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import "AudioPlayerViewController.h"

@interface AudioPlayerViewController ()

@property (nonatomic, strong) UILabel *errorLabel;
@property (nonatomic, strong) UILabel *secondsRemaining;
@property (nonatomic, strong) UILabel *secondsElapsed;

@property (nonatomic, strong) UIImageView *albumArtwork;

@property (nonatomic, strong) UIButton *pausePlay;
@property (nonatomic, strong) UIButton *stopButton;
@property (nonatomic, strong) UIButton *nxtTrack;
@property (nonatomic, strong) UIButton *prevTrack;

@property (nonatomic, strong) MPVolumeView *volumeView;

@property (nonatomic, strong) MarqueeLabel *artistLabel;
@property (nonatomic, strong) MarqueeLabel *titleLabel;
@property (nonatomic, strong) MarqueeLabel *albumLabel;

@property (nonatomic, strong) UISlider *time;
@property (nonatomic, strong) UINavigationBar *navBar;

@property (nonatomic, strong) TextToggleControl *loopControl;

@property (nonatomic, strong) UIActionSheet *popupQuery;

@end

@implementation AudioPlayerViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [MarqueeLabel controllerViewAppearing:self];
    
    if ([kAppDelegate audioPlayer].isPlaying) {
        [_pausePlay setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
        [_pausePlay setImage:[UIImage imageNamed:@"pause_selected"] forState:UIControlStateHighlighted];
    } else {
        [_pausePlay setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
        [_pausePlay setImage:[UIImage imageNamed:@"play_selected"] forState:UIControlStateHighlighted];
    }
}

- (void)loadView {
    [super loadView];
    
    [self setupNotifs];
    
    CGRect screenBounds = [[UIScreen mainScreen]bounds];
    BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    
    self.navBar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 64)];
    _navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:[[kAppDelegate openFile]lastPathComponent]];
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showActionSheet:)];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    [_navBar pushNavigationItem:topItem animated:YES];
    [self.view addSubview:_navBar];
    
    self.artistLabel = [[MarqueeLabel alloc]initWithFrame:CGRectMake(0, 64+10, screenBounds.size.width, 20) rate:50.0f andFadeLength:10.0f];
    _artistLabel.animationDelay = 0.5f;
    _artistLabel.marqueeType = MLContinuous;
    _artistLabel.animationCurve = UIViewAnimationCurveLinear;
    _artistLabel.numberOfLines = 1;
    _artistLabel.textAlignment = NSTextAlignmentCenter;
    _artistLabel.backgroundColor = [UIColor clearColor];
    _artistLabel.textColor = [UIColor blackColor];
    _artistLabel.font = [UIFont systemFontOfSize:15];
    [self.view addSubview:_artistLabel];
    
    self.titleLabel = [[MarqueeLabel alloc]initWithFrame:CGRectMake(0, 64+10+20, screenBounds.size.width, 20) rate:50.0f andFadeLength:10.0f];
    _titleLabel.animationDelay = 0.5f;
    _titleLabel.marqueeType = MLContinuous;
    _titleLabel.animationCurve = UIViewAnimationCurveLinear;
    _titleLabel.numberOfLines = 1;
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.backgroundColor = [UIColor clearColor];
    _titleLabel.textColor = [UIColor blackColor];
    _titleLabel.font = [UIFont boldSystemFontOfSize:15];
    [self.view addSubview:_titleLabel];
    
    self.albumLabel = [[MarqueeLabel alloc]initWithFrame:CGRectMake(0, 64+10+(20*2), screenBounds.size.width, 20) rate:50.0f andFadeLength:10.0f];
    _albumLabel.animationDelay = 0.5f;
    _albumLabel.marqueeType = MLContinuous;
    _albumLabel.animationCurve = UIViewAnimationCurveLinear;
    _albumLabel.numberOfLines = 1;
    _albumLabel.textAlignment = NSTextAlignmentCenter;
    _albumLabel.backgroundColor = [UIColor clearColor];
    _albumLabel.textColor = [UIColor blackColor];
    _albumLabel.font = [UIFont systemFontOfSize:15];
    [self.view addSubview:_albumLabel];
    
    self.secondsElapsed = [[UILabel alloc]initWithFrame:CGRectMake(0, 114+5+20, 44, 23)];
    _secondsElapsed.font = [UIFont boldSystemFontOfSize:15];
    _secondsElapsed.textColor = [UIColor blackColor];
    _secondsElapsed.backgroundColor = [UIColor clearColor];
    _secondsElapsed.textAlignment = NSTextAlignmentRight;
    _secondsElapsed.text = @"0:00";
    [self.view addSubview:_secondsElapsed];
    
    self.time = [[UISlider alloc]initWithFrame:CGRectMake(44, 114+20, screenBounds.size.width-88, 23)];
    [_time setMinimumTrackImage:[UIImage imageNamed:@"trackImage"] forState:UIControlStateNormal];
    [_time setMaximumTrackImage:[UIImage imageNamed:@"trackImage"] forState:UIControlStateNormal];
    [_time setThumbImage:[UIImage imageNamed:@"scrubber"] forState:UIControlStateHighlighted];
    [_time setThumbImage:[UIImage imageNamed:@"scrubber"] forState:UIControlStateNormal];
    [_time addTarget:self action:@selector(sliderChanged) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_time];
    
    self.secondsRemaining = [[UILabel alloc]initWithFrame:CGRectMake(screenBounds.size.width-44, 114+5+20, 44, 23)];
    _secondsRemaining.font = [UIFont boldSystemFontOfSize:15];
    _secondsRemaining.textColor = [UIColor blackColor];
    _secondsRemaining.backgroundColor = [UIColor clearColor];
    _secondsRemaining.textAlignment = NSTextAlignmentLeft;
    _secondsRemaining.text = @"-0:00";
    [self.view addSubview:_secondsRemaining];
    
    self.albumArtwork = [[UIImageView alloc]initWithFrame:CGRectMake(0, 200, screenBounds.size.width, screenBounds.size.height-300)];
    _albumArtwork.contentMode = UIViewContentModeScaleAspectFit;
    _albumArtwork.layer.masksToBounds = YES;
    _albumArtwork.layer.cornerRadius = 5.0f;
    _albumArtwork.layer.borderWidth = 1.0f;
    _albumArtwork.layer.borderColor = [UIColor colorWithRed:105.0f/255.0f green:54.0f/255.0f blue:153.0f/255.0f alpha:1.0f].CGColor;
    [self.view addSubview:_albumArtwork];
    
    float controlsWidth = screenBounds.size.width/3;
    
    self.prevTrack = [[UIButton alloc]initWithFrame:CGRectMake(0, screenBounds.size.height-55, controlsWidth, 46)];
    _prevTrack.backgroundColor = [UIColor clearColor];
    [_prevTrack setImage:[UIImage imageNamed:@"back_button"] forState:UIControlStateNormal];
    [_prevTrack setImage:[UIImage imageNamed:@"back_button_pressed"] forState:UIControlStateHighlighted];
    [_prevTrack addTarget:kAppDelegate action:@selector(skipToPreviousTrack) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_prevTrack];
    
    self.pausePlay = [[UIButton alloc]initWithFrame:CGRectMake(controlsWidth, screenBounds.size.height-55, controlsWidth, 46)];
    _pausePlay.backgroundColor = [UIColor clearColor];
    [_pausePlay setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
    [_pausePlay setImage:[UIImage imageNamed:@"pause_selected"] forState:UIControlStateHighlighted];
    [_pausePlay addTarget:kAppDelegate action:@selector(togglePlayPause) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_pausePlay];
    
    self.nxtTrack = [[UIButton alloc]initWithFrame:CGRectMake(controlsWidth*2, screenBounds.size.height-55, controlsWidth, 46)];
    _nxtTrack.backgroundColor = [UIColor clearColor];
    [_nxtTrack setImage:[UIImage imageNamed:@"next_button"] forState:UIControlStateNormal];
    [_nxtTrack setImage:[UIImage imageNamed:@"next_button_pressed"] forState:UIControlStateHighlighted];
    [_nxtTrack addTarget:kAppDelegate action:@selector(skipToNextTrack) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_nxtTrack];
    
    self.volumeView = [[MPVolumeView alloc]initWithFrame:CGRectMake(30, screenBounds.size.height-85, screenBounds.size.width-60, 25)];
    _volumeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [_volumeView setMinimumVolumeSliderImage:[UIImage imageNamed:@"trackImage"] forState:UIControlStateNormal];
    [_volumeView setMaximumVolumeSliderImage:[UIImage imageNamed:@"trackImage"] forState:UIControlStateNormal];
    [_volumeView setVolumeThumbImage:[UIImage imageNamed:@"scrubber_volume"] forState:UIControlStateNormal];
    [_volumeView setVolumeThumbImage:[UIImage imageNamed:@"scrubber_volume"] forState:UIControlStateHighlighted];
    [_volumeView setRouteButtonImage:[[_volumeView routeButtonImageForState:UIControlStateNormal]imageFilledWith:[UIColor colorWithRed:105.0f/255.0f green:54.0f/255.0f blue:153.0f/255.0f alpha:0.0f]] forState:UIControlStateNormal];
    [self.view addSubview:_volumeView];
    
    self.loopControl = [TextToggleControl control];
    _loopControl.frame = CGRectMake((screenBounds.size.width/2)-30, 160, 60, 30);
    _loopControl.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    _loopControl.backgroundColor = [UIColor clearColor];
    [_loopControl addTarget:self action:@selector(loopControlPressed) forControlEvents:UIControlEventTouchUpInside];
    [_loopControl setColor:[UIColor colorWithRed:105.0f/255.0f green:54.0f/255.0f blue:153.0f/255.0f alpha:1.0f] forState:ToggleControlModeOn];
    [_loopControl setColor:[UIColor lightGrayColor] forState:ToggleControlModeOff];
    [_loopControl setColor:[UIColor whiteColor] forState:ToggleControlModeIntermediate];
    [_loopControl setTitle:@"Loop" forState:UIControlStateNormal];
    [self.view addSubview:_loopControl];
    
    self.errorLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 44+20, screenBounds.size.width, screenBounds.size.height-88)];
    _errorLabel.text = @"Error Playing Audio";
    _errorLabel.backgroundColor = [UIColor clearColor];
    _errorLabel.textColor = [UIColor blackColor];
    _errorLabel.font = [UIFont boldSystemFontOfSize:iPad?72:33];
    _errorLabel.hidden = YES;
    _errorLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_errorLabel];
    
    [self.view sendSubviewToBack:_albumArtwork];

    [kAppDelegate playFile:kAppDelegate.openFile];
    
    [self refreshLoopState];
    [MarqueeLabel controllerLabelsShouldAnimate:self];
}

- (void)loopControlPressed {
    self.isLooped = _loopControl.on;
    [[NSUserDefaults standardUserDefaults]setBool:_isLooped forKey:@"loop"];
    [kAppDelegate audioPlayer].numberOfLoops = _isLooped?-1:0;
}

- (void)setLoopState:(BOOL)on {
    self.isLooped = on;
    [[NSUserDefaults standardUserDefaults]setBool:_isLooped forKey:@"loop"];
}

- (void)refreshLoopState {
    self.isLooped = [[NSUserDefaults standardUserDefaults]boolForKey:@"loop"];
    [kAppDelegate audioPlayer].numberOfLoops = _isLooped?-1:0;
    [_loopControl setOn:_isLooped];
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
    [_prevTrack setHidden:hide];
    [_nxtTrack setHidden:hide];
    [_volumeView setHidden:hide];
    [_albumArtwork setHidden:hide];
    [_errorLabel setHidden:!hide];
}

- (void)close {
    AppDelegate *ad = kAppDelegate;
    
    if (!ad.audioPlayer.isPlaying) {
        [ad.audioPlayer stop];
        [ad setAudioPlayer:nil];
        [ad setNowPlayingFile:nil];
    }
    
    [HamburgerView reloadCells];
    
    [self stopUpdatingTime];
    
    [ad setOpenFile:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)startUpdatingTime {
    self.shouldStopCounter = NO;
    
    if (_isGoing) {
        return;
    }

    __weak AudioPlayerViewController *weakself = self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        @autoreleasepool {
            while (!weakself.shouldStopCounter) {
                [NSThread sleepForTimeInterval:0.1f];
                dispatch_sync(dispatch_get_main_queue(), ^{
                    @autoreleasepool {
                        weakself.isGoing = YES;
                        [weakself updateTime];
                    }
                });
            }
            weakself.isGoing = NO;
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
    
    if (_popupQuery && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [_popupQuery dismissWithClickedButtonIndex:_popupQuery.cancelButtonIndex animated:YES];
        self.popupQuery = nil;
        return;
    }
        
    NSString *file = [kAppDelegate openFile];
    
    __weak AudioPlayerViewController *weakself = self;
    
    self.popupQuery = [[UIActionSheet alloc]initWithTitle:[NSString stringWithFormat:@"What would you like to do with %@?",file.lastPathComponent] completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
        NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
        
        if ([title isEqualToString:kActionButtonNameEmail]) {
            [kAppDelegate sendFileInEmail:file];
        } else if ([title isEqualToString:kActionButtonNameP2P]) {
            [[BTManager shared]sendFileAtPath:file];
        } else if ([title isEqualToString:kActionButtonNameDBUpload]) {
            [[TaskController sharedController]addTask:[DropboxUpload uploadWithFile:file]];
        } else if ([title isEqualToString:kActionButtonNameEditID3]) {
            [weakself presentViewController:[EditID3ViewController viewControllerWhite] animated:YES completion:nil];
        }
    } cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:kActionButtonNameEmail, kActionButtonNameP2P, kActionButtonNameDBUpload, kActionButtonNameEditID3, nil];

    if (_errorLabel.hidden && [file.pathExtension.lowercaseString isEqualToString:@"mp3"]) {
        [_popupQuery addButtonWithTitle:@"Edit Metadata"];
    }
    
    [_popupQuery addButtonWithTitle:@"Cancel"];
    [_popupQuery setCancelButtonIndex:_popupQuery.numberOfButtons-1];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [_popupQuery showFromBarButtonItem:(UIBarButtonItem *)sender animated:YES];
    } else {
        [_popupQuery showInView:self.view];
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
    
    [self updateTime];
    
    AppDelegate *ad = kAppDelegate;
    
    if (ad.audioPlayer.isPlaying) {
        [ad.audioPlayer pause];
        [_pausePlay setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
        [_pausePlay setImage:[UIImage imageNamed:@"play_pressed"] forState:UIControlStateHighlighted];
        [self stopUpdatingTime];
    } else {
        [ad.audioPlayer play];
        [_pausePlay setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
        [_pausePlay setImage:[UIImage imageNamed:@"pause_pressed"] forState:UIControlStateHighlighted];
        [ad setNowPlayingFile:ad.openFile];
        [self startUpdatingTime];
    }
}

#pragma mark Inter-ViewController controls

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
    [self hideControls:[notif.object isEqualToString:@"YES"]];
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
        _artistLabel.text = (NSString *)components[0];
        _titleLabel.text = (NSString *)components[1];
        _albumLabel.text = (NSString *)components[2];
    }
}

- (void)setSongTitleText:(NSNotification *)notif {
    _navBar.topItem.title = notif.object;
}

- (void)setArtwork:(NSNotification *)notif {
    @autoreleasepool {
        CGRect screenBounds = [[UIScreen mainScreen]bounds];
        CGRect targetRect = CGRectMake(20, 200, screenBounds.size.width-20, screenBounds.size.height-300);
        
        UIImage *image = (UIImage *)notif.object;
        
        CGPoint oldCenter = _albumArtwork.center;
        
        _albumArtwork.bounds = CGRectMake(0, 0, image.size.width, image.size.height);
        
        if (image.size.height > targetRect.size.height) {
            float ratio = (image.size.height/targetRect.size.height);
            _albumArtwork.bounds = CGRectMake(0, 0, image.size.width/ratio, targetRect.size.height);
        } else if (image.size.width > targetRect.size.width) {
            float ratio = (image.size.width/targetRect.size.width);
            _albumArtwork.bounds = CGRectMake(0, 0, targetRect.size.width, image.size.height/ratio);
        }
        
        _albumArtwork.center = oldCenter;
        _albumArtwork.image = image;
    }
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
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(setArtwork:) name:@"setArtwork:" object:nil];
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

+ (void)notif_setAlbumArt:(UIImage *)art {
    [[NSNotificationCenter defaultCenter]postNotificationName:@"setArtwork:" object:art];
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
