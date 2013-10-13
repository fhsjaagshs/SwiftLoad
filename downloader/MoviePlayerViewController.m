//
//  moviePlayerView.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 12/8/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import "MoviePlayerViewController.h"

@interface MoviePlayerViewController ()

@property (nonatomic, assign) BOOL shouldUnpauseAudioPlayer;
@property (nonatomic, strong) NSURL *streamingUrl;

@property (nonatomic, strong) MPMoviePlayerController *moviePlayer;
@property (nonatomic, strong) UINavigationBar *bar;

@property (nonatomic, assign) BOOL shouldKillNAI;

@end

@implementation MoviePlayerViewController

+ (MoviePlayerViewController *)moviePlayerWithStreamingURL:(NSURL *)url {
    return [[[self class]alloc]initWithStreamingURL:url];
}

- (instancetype)initWithStreamingURL:(NSURL *)url {
    self = [super init];
    if (self) {
        self.streamingUrl = url;
        self.view.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)loadView {
    [super loadView];
    
    CGRect screenBounds = [[UIScreen mainScreen]bounds];
    
    self.bar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 64)];
    _bar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:_streamingUrl?@"Loading...":self.openFile.lastPathComponent];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    
    if (!_streamingUrl) {
        topItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showActionSheet:)];
    } else {
        [[NetworkActivityController sharedController]incrementCount];
    }
    
    [_bar pushNavigationItem:topItem animated:NO];
    [self.view addSubview:_bar];
    
    self.shouldUnpauseAudioPlayer = NO;

    if (kAppDelegate.audioPlayer.isPlaying) {
        [kAppDelegate.audioPlayer pause];
        self.shouldUnpauseAudioPlayer = YES;
    }

    self.moviePlayer = [[MPMoviePlayerController alloc]initWithContentURL:(_streamingUrl.absoluteString.length > 0)?_streamingUrl:[NSURL fileURLWithPath:self.openFile]];
    _moviePlayer.scalingMode = MPMovieScalingModeAspectFit;
    _moviePlayer.repeatMode = MPMovieRepeatModeNone;
    [_moviePlayer.backgroundView removeFromSuperview];
    _moviePlayer.view.frame = CGRectMake(0, 64, self.view.bounds.size.width, self.view.bounds.size.height-64);
    _moviePlayer.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_moviePlayer.view];
    
    [_moviePlayer prepareToPlay];
    [_moviePlayer play];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(moviePlayerDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(moviePlayerDidLoadData:) name:MPMoviePlayerReadyForDisplayDidChangeNotification object:nil];
}

- (void)close {
    if (_shouldKillNAI) {
        [[NetworkActivityController sharedController]hideIfPossible];
    }
    
    if (_moviePlayer.view.superview) {
        [_moviePlayer.view removeFromSuperview];
    }
    
    [_moviePlayer stop];
    
    [self dismissViewControllerAnimated:YES completion:^{
        AppDelegate *ad = kAppDelegate;
        
        if (_shouldUnpauseAudioPlayer) {
            [ad.audioPlayer prepareToPlay];
            [ad.audioPlayer play];
        }
    }];
}

- (void)actionSheet:(UIActionSheet *)actionSheet selectedIndex:(NSUInteger)buttonIndex {
    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if ([title isEqualToString:kActionButtonNameEmail]) {
        [kAppDelegate sendFileInEmail:self.openFile];
    } else if ([title isEqualToString:kActionButtonNameP2P]) {
        [[P2PManager shared]sendFileAtPath:self.openFile];
    } else if ([title isEqualToString:kActionButtonNameDBUpload]) {
        [[TaskController sharedController]addTask:[DropboxUpload uploadWithFile:self.openFile]];
    }
}

- (void)showActionSheet:(id)sender {
    [self showActionSheetFromBarButtonItem:(UIBarButtonItem *)sender withButtonTitles:@[kActionButtonNameEmail, kActionButtonNameP2P, kActionButtonNameDBUpload]];
}

- (void)moviePlayerDidFinish:(NSNotification *)notification {
    [_moviePlayer stop];
    _moviePlayer.initialPlaybackTime = -1;
}

- (void)moviePlayerDidLoadData:(NSNotification *)notif {
    if (_moviePlayer.readyForDisplay && _streamingUrl) {
        self.shouldKillNAI = NO;
        [[NetworkActivityController sharedController]hideIfPossible];
        _bar.topItem.title = [_streamingUrl.absoluteString.lastPathComponent stringByRemovingPercentEncoding];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end
