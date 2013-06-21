//
//  AudioPlayerViewController.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 8/11/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomButton.h"
#import "Common.h"
#import "CustomSegmentedControl.h"
#import "BackAndForwardButton.h"
#import "CustomNavBar.h"
#import "CustomSlider.h"

@interface AudioPlayerViewController : UIViewController

@property (nonatomic, retain) UILabel *secondsDisplay;
@property (nonatomic, retain) UILabel *errorLabel;
@property (nonatomic, retain) UILabel *secondsRemaining;
@property (nonatomic, retain) CustomSegmentedControl *control;

@property (nonatomic, retain) CustomButton *pausePlay;
@property (nonatomic, retain) CustomButton *stopButton;
@property (nonatomic, retain) BackAndForwardButton *nxtTrack;
@property (nonatomic, retain) BackAndForwardButton *prevTrack;
@property (nonatomic, retain) UITextView *infoField;
@property (nonatomic, retain) CustomSlider *time;
@property (nonatomic, retain) UINavigationBar *navBar;

@property (nonatomic, retain) UIActionSheet *popupQuery;

@property (nonatomic, assign) BOOL shouldStopCounter;
@property (nonatomic, assign) BOOL notInPlayerView;
@property (nonatomic, assign) BOOL isGoing;

+ (void)notif_setPausePlayTitlePlay;
+ (void)notif_setPausePlayTitlePause;
+ (void)notif_setLoop;
+ (void)notif_setControlsHidden:(BOOL)flag;
+ (void)notif_setNxtTrackHidden:(BOOL)flag;
+ (void)notif_setPrevTrackHidden:(BOOL)flag;
+ (void)notif_setInfoFieldText:(NSString *)string;
+ (void)notif_setSongTitleText:(NSString *)string;
//+ (void)notif_setShouldStopPlayingAudio:(BOOL)flag;
+ (void)notif_setShouldUpdateTime:(BOOL)flag;

@end

