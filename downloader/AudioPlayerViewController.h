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

#define _audioPlayer (AVAudioPlayer *)[[(downloaderAppDelegate *)[[UIApplication sharedApplication]delegate]viewController]audioPlayer]

@interface AudioPlayerViewController : UIViewController {
    BOOL shouldStopCounter;
    BOOL notInPlayerView;
}

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
@property (nonatomic, retain) CustomNavBar *navBar;

@property (nonatomic, retain) UIActionSheet *popupQuery;

+ (void)notif_setPausePlayTitlePlay;
+ (void)notif_setPausePlayTitlePause;
+ (void)notif_setLoop;
+ (void)notif_setControlsHidden:(BOOL)flag;
+ (void)notif_setNxtTrackHidden:(BOOL)flag;
+ (void)notif_setPrevTrackHidden:(BOOL)flag;
+ (void)notif_setInfoFieldText:(NSString *)string;
+ (void)notif_setSongTitleText:(NSString *)string;

@end

