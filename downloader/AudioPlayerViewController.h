//
//  AudioPlayerViewController.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 8/11/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomSlider.h"

@interface AudioPlayerViewController : UIViewController

@property (nonatomic, strong) UILabel *secondsDisplay;
@property (nonatomic, strong) UILabel *errorLabel;
@property (nonatomic, strong) UILabel *secondsRemaining;

@property (nonatomic, strong) UIButton *pausePlay;
@property (nonatomic, strong) UIButton *stopButton;
@property (nonatomic, strong) UIButton *nxtTrack;
@property (nonatomic, strong) UIButton *prevTrack;
@property (nonatomic, strong) UITextView *infoField;
@property (nonatomic, strong) CustomSlider *time;
@property (nonatomic, strong) ShadowedNavBar *navBar;

@property (nonatomic, strong) ToggleControl *loopControl;

@property (nonatomic, strong) UIActionSheet *popupQuery;

@property (nonatomic, assign) BOOL shouldStopCounter;
@property (nonatomic, assign) BOOL notInPlayerView;
@property (nonatomic, assign) BOOL isGoing;
@property (nonatomic, assign) BOOL isLooped;

+ (void)notif_setPausePlayTitlePlay;
+ (void)notif_setPausePlayTitlePause;
+ (void)notif_setLoop;
+ (void)notif_setControlsHidden:(BOOL)flag;
+ (void)notif_setNxtTrackHidden:(BOOL)flag;
+ (void)notif_setPrevTrackHidden:(BOOL)flag;
+ (void)notif_setInfoFieldText:(NSString *)string;
+ (void)notif_setSongTitleText:(NSString *)string;
+ (void)notif_setShouldUpdateTime:(BOOL)flag;

@end

