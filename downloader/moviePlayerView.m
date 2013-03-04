//
//  moviePlayerView.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 12/8/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
// 

#import "moviePlayerView.h"

@implementation moviePlayerView

@synthesize moviePlayer, popupQuery;

- (void)loadView {
    [super loadView];
    self.view.backgroundColor = [UIColor clearColor];
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    CustomNavBar *bar = [[CustomNavBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)];
    bar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:[[kAppDelegate openFile]lastPathComponent]];
    topItem.leftBarButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)]autorelease];
    topItem.rightBarButtonItem = [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showActionSheet:)]autorelease];
    [bar pushNavigationItem:topItem animated:NO];
    [self.view addSubview:bar];
    [self.view bringSubviewToFront:bar];
    [bar release];
    [topItem release];
    
    shouldUnpauseAudioPlayer = NO;
    
    if ([_audioPlayer isPlaying]) {
        [_audioPlayer pause];
        shouldUnpauseAudioPlayer = YES;
    }
    
    NSString *moviePath = [kAppDelegate openFile];
    NSURL *theMovieURL = [NSURL fileURLWithPath:moviePath];
    
    MPMoviePlayerController *mpc = [[MPMoviePlayerController alloc]initWithContentURL:theMovieURL];
    [self setMoviePlayer:mpc];
    [mpc release];
    
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
        [_audioPlayer prepareToPlay];
        [_audioPlayer play];
    }

    [self dismissModalViewControllerAnimated:YES];
    [kAppDelegate setOpenFile:nil];
}

- (void)addToTheRoll {
    
    [kAppDelegate showHUDWithTitle:@"Working..."];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
        
        NSString *file = [kAppDelegate openFile];
        UISaveVideoAtPathToSavedPhotosAlbum(file, nil, nil, nil);
        
        [NSThread sleepForTimeInterval:0.5f];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSAutoreleasePool *poolTwo = [[NSAutoreleasePool alloc]init];
            
            NSString *fileName = [file lastPathComponent];
            
            if (fileName.length > 14) {
                fileName = [[fileName substringToIndex:11]stringByAppendingString:@"..."];
            }
            
            UIImageView *checkmark = [[UIImageView alloc]initWithImage:getCheckmarkImage()];
            
            [kAppDelegate hideHUD];
            
            [kAppDelegate showHUDWithTitle:@"Imported"];
            [kAppDelegate setSecondaryTitleOfVisibleHUD:fileName];
            [kAppDelegate setVisibleHudMode:MBProgressHUDModeCustomView];
            [kAppDelegate setVisibleHudCustomView:checkmark];
            [kAppDelegate hideVisibleHudAfterDelay:1.0f];
            [checkmark release];
            [poolTwo release];
        });
        
        [pool release];
    });
}

- (void)showActionSheet:(id)sender {
    NSString *file = [kAppDelegate openFile];
    NSString *fileName = [file lastPathComponent];
    NSString *message = [NSString stringWithFormat:@"What would you like to do with %@?",fileName];
    
    self.popupQuery = [[[UIActionSheet alloc]initWithTitle:message completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
        NSString *file = [kAppDelegate openFile];
        NSString *fileName = [file lastPathComponent];
        
        if (buttonIndex == 0) {
            [kAppDelegate sendFileInEmail:file fromViewController:self];
        } else if (buttonIndex == 1) {
            [kAppDelegate showBTController];
        } else if (buttonIndex == 2) {
            [kAppDelegate showFTPUploadController];
        } else if (buttonIndex == 3) {
            if ([[[file pathExtension]lowercaseString]isEqualToString:@"mp4"]) {
                [self addToTheRoll];
            } else {
                NSString *message = [NSString stringWithFormat:@"Sorry, the file \"%@\" is not supported by this feature because it is not in MPEG-4 format.",fileName];
                CustomAlertView *av = [[CustomAlertView alloc] initWithTitle:@"Failure Eporting Video" message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [av show];
                [av release];
            }
        } else if (buttonIndex == 4) {
            [self uploadToDropbox];
        }
    } cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Email File", @"Send Via Bluetooth", @"Upload to Server", @"Save to Camera Roll", @"Upload to Dropbox", nil]autorelease];
    
    self.popupQuery.actionSheetStyle = UIActionSheetStyleBlackTranslucent;

    if (!self.popupQuery.isVisible) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            [self.popupQuery showFromBarButtonItem:(UIBarButtonItem *)sender animated:YES];
        } else {
            [self.popupQuery showInView:self.view];
        }
    } else {
        [self.popupQuery dismissWithClickedButtonIndex:[self.popupQuery cancelButtonIndex] animated:YES];
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
    [self setPopupQuery:nil];
    [self setMoviePlayer:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    NSLog(@"%@ dealloc'd", NSStringFromClass([self class]));
    [super dealloc];
}

@end
