//
//  AudioPlayerViewController.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 8/11/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AudioPlayerViewController : UIViewController

@property (nonatomic, assign) BOOL shouldStopCounter;
@property (nonatomic, assign) BOOL notInPlayerView;
@property (nonatomic, assign) BOOL isGoing;
@property (nonatomic, assign) BOOL isLooped;

+ (void)notif_setPausePlayTitlePlay;
+ (void)notif_setPausePlayTitlePause;
+ (void)notif_setLoop;
+ (void)notif_setControlsHidden:(BOOL)flag;
+ (void)notif_setInfoFieldText:(NSString *)string;
+ (void)notif_setSongTitleText:(NSString *)string;
+ (void)notif_setShouldUpdateTime:(BOOL)flag;

@end

