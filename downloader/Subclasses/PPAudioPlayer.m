//
//  PPAudioPlayer.m
//  Swift
//
//  Created by Nathaniel Symer on 10/3/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "PPAudioPlayer.h"

@implementation PPAudioPlayer

@dynamic delegate;

- (BOOL)play {
    BOOL success = [super play];
    
    if (success) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(audioPlayerDidPlay:)]) {
            [self.delegate audioPlayerDidPlay:self];
        }
    }
    
    return success;
}

- (BOOL)playAtTime:(NSTimeInterval)time {
    
    BOOL success = [super playAtTime:time];
    
    if (success) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(audioPlayerDidPlay:)]) {
            [self.delegate audioPlayerDidPlay:self];
        }
    }
    
    return success;
}

- (void)pause {
    [super pause];
    if (self.delegate && [self.delegate respondsToSelector:@selector(audioPlayerDidPause:)]) {
        [self.delegate audioPlayerDidPause:self];
    }
}

- (void)stop {
    [super stop];
    if (self.delegate && [self.delegate respondsToSelector:@selector(audioPlayerDidStop:)]) {
        [self.delegate audioPlayerDidStop:self];
    }
}

@end