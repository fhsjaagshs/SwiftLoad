//
//  downloaderViewController.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 8/11/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

void audioRouteChangeListenerCallback(void *inUserData, AudioSessionPropertyID inPropertyID, UInt32 inPropertyValueSize, const void *inPropertyValue);

@interface downloaderViewController : UIViewController <UIAlertViewDelegate, AVAudioPlayerDelegate>

@property (nonatomic, retain) AVAudioPlayer *audioPlayer;

- (void)skipToPreviousTrack;
- (void)skipToNextTrack;
- (void)togglePlayPause;

- (void)showArtworkForFile:(NSString *)file;
- (void)showMetadataInLockscreenWithArtist:(NSString *)artist title:(NSString *)title album:(NSString *)album;

@property (nonatomic, retain) UITextField *textField;

@end
