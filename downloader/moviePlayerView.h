//
//  moviePlayerView.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 12/8/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface moviePlayerView : UIViewController {
    BOOL shouldUnpauseAudioPlayer;
}

@property (nonatomic, retain) UIActionSheet *popupQuery;
@property (nonatomic, retain) MPMoviePlayerController *moviePlayer;

@end
