//
//  moviePlayerView.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 12/8/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
// 

#import "moviePlayerView.h"

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
    
    shouldUnpauseAudioPlayer = NO;
    
    if ([[kAppDelegate audioPlayer]isPlaying]) {
        [[kAppDelegate audioPlayer]pause];
        shouldUnpauseAudioPlayer = YES;
    }
    
    NSString *moviePath = [kAppDelegate openFile];
    NSURL *theMovieURL = [NSURL fileURLWithPath:moviePath];
    
    MPMoviePlayerController *mpc = [[MPMoviePlayerController alloc]initWithContentURL:theMovieURL];
    [self setMoviePlayer:mpc];
    
    self.moviePlayer.scalingMode = MPMovieScalingModeAspectFit;
    self.moviePlayer.repeatMode = MPMovieRepeatModeNone;
    [self.moviePlayer.backgroundView removeFromSuperview];
    [self.view addSubview:self.moviePlayer.view];
    
    self.moviePlayer.view.frame = CGRectMake(0, 44, self.view.bounds.size.width, self.view.bounds.size.height-44);
    self.moviePlayer.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self.moviePlayer prepareToPlay];
    [self.moviePlayer play];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(moviePlayerDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
}

- (void)uploadToDropbox {
    if (![[DBSession sharedSession]isLinked]) {
        [[DBSession sharedSession]linkFromController:self];
    } else {
        [kAppDelegate uploadLocalFile:[kAppDelegate openFile]];
    }
}

- (void)close {
    if (self.moviePlayer.view.superview) {
        [self.moviePlayer.view removeFromSuperview];
    }
    
    [self.moviePlayer stop];
    
    if (shouldUnpauseAudioPlayer) {
        [[kAppDelegate audioPlayer]prepareToPlay];
        [[kAppDelegate audioPlayer]play];
    }

    [self dismissModalViewControllerAnimated:YES];
    [kAppDelegate setOpenFile:nil];
}

- (void)showActionSheet:(id)sender {
    
    if (self.popupQuery && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.popupQuery dismissWithClickedButtonIndex:self.popupQuery.cancelButtonIndex animated:YES];
        self.popupQuery = nil;
        return;
    }
    
    self.popupQuery = [[UIActionSheet alloc]initWithTitle:[NSString stringWithFormat:@"What would you like to do with %@?",[[kAppDelegate openFile]lastPathComponent]] completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
        if (buttonIndex == 0) {
            [kAppDelegate sendFileInEmail:[kAppDelegate openFile] fromViewController:self];
        } else if (buttonIndex == 1) {
            [kAppDelegate showBTController];
        } else if (buttonIndex == 2) {
            [kAppDelegate showFTPUploadController];
        } else if (buttonIndex == 3) {
            [self uploadToDropbox];
        }
    } cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Email File", @"Send Via Bluetooth", @"Upload to Server", @"Upload to Dropbox", nil];
    
    self.popupQuery.actionSheetStyle = UIActionSheetStyleBlackTranslucent;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.popupQuery showFromBarButtonItem:(UIBarButtonItem *)sender animated:YES];
    } else {
        [self.popupQuery showInView:self.view];
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)moviePlayerDidFinish:(NSNotification *)notification {
    [self.moviePlayer stop];
    self.moviePlayer.initialPlaybackTime = -1;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    NSLog(@"%@ dealloc'd", NSStringFromClass([self class]));
}

@end
