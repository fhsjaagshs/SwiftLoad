//
//  moviePlayerView.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 12/8/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
// 

#import "moviePlayerView.h"

@interface moviePlayerView ()

@property (nonatomic, assign) BOOL shouldUnpauseAudioPlayer;

@end

@implementation moviePlayerView

- (void)loadView {
    [super loadView];
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    UINavigationBar *bar = [[ShadowedNavBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)];
    bar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:[[kAppDelegate openFile]lastPathComponent]];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showActionSheet:)];
    [bar pushNavigationItem:topItem animated:NO];
    [self.view addSubview:bar];
    [self.view bringSubviewToFront:bar];
    
    self.shouldUnpauseAudioPlayer = NO;
    
    AppDelegate *ad = kAppDelegate;
    
    if (ad.audioPlayer.isPlaying) {
        [ad.audioPlayer pause];
        self.shouldUnpauseAudioPlayer = YES;
    }

    self.moviePlayer = [[MPMoviePlayerController alloc]initWithContentURL:[NSURL fileURLWithPath:[kAppDelegate openFile]]];
    _moviePlayer.scalingMode = MPMovieScalingModeAspectFit;
    _moviePlayer.repeatMode = MPMovieRepeatModeNone;
    [_moviePlayer.backgroundView removeFromSuperview];
    _moviePlayer.view.frame = CGRectMake(0, 44, self.view.bounds.size.width, self.view.bounds.size.height-44);
    _moviePlayer.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_moviePlayer.view];
    
    [_moviePlayer prepareToPlay];
    [_moviePlayer play];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(moviePlayerDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
}

- (void)close {
    if (self.moviePlayer.view.superview) {
        [self.moviePlayer.view removeFromSuperview];
    }
    
    [self.moviePlayer stop];
    
    AppDelegate *ad = kAppDelegate;
    
    if (self.shouldUnpauseAudioPlayer) {
        [ad.audioPlayer prepareToPlay];
        [ad.audioPlayer play];
    }

    [self dismissModalViewControllerAnimated:YES];
    [ad setOpenFile:nil];
}

- (void)showActionSheet:(id)sender {
    
    if (_popupQuery && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [_popupQuery dismissWithClickedButtonIndex:_popupQuery.cancelButtonIndex animated:YES];
        self.popupQuery = nil;
        return;
    }
    
    self.popupQuery = [[UIActionSheet alloc]initWithTitle:[NSString stringWithFormat:@"What would you like to do with %@?",[[kAppDelegate openFile]lastPathComponent]] completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
        if (buttonIndex == 0) {
            [kAppDelegate sendFileInEmail:[kAppDelegate openFile] fromViewController:self];
        } else if (buttonIndex == 1) {
            BluetoothTask *task = [BluetoothTask taskWithFile:[kAppDelegate openFile]];
            [[TaskController sharedController]addTask:task];
        } else if (buttonIndex == 2) {
            [kAppDelegate uploadLocalFile:[kAppDelegate openFile] fromViewController:self];
        }
    } cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Email File", @"Send Via Bluetooth", @"Upload to Dropbox", nil];
    
    _popupQuery.actionSheetStyle = UIActionSheetStyleBlackTranslucent;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [_popupQuery showFromBarButtonItem:(UIBarButtonItem *)sender animated:YES];
    } else {
        [_popupQuery showInView:self.view];
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)moviePlayerDidFinish:(NSNotification *)notification {
    [_moviePlayer stop];
    _moviePlayer.initialPlaybackTime = -1;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end
