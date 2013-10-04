//
//  PPAudioPlayer.h
//  Swift
//
//  Created by Nathaniel Symer on 10/3/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@class PPAudioPlayer;

@protocol PPAudioPlayerDelegate <NSObject, AVAudioPlayerDelegate>

@optional
- (void)audioPlayerDidPlay:(PPAudioPlayer *)audioPlayer;
- (void)audioPlayerDidPause:(PPAudioPlayer *)audioPlayer;
- (void)audioPlayerDidStop:(PPAudioPlayer *)audioPlayer;

@end

@interface PPAudioPlayer : AVAudioPlayer

@property (assign) id<PPAudioPlayerDelegate> delegate;

@end


