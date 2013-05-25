//
//  BTSender.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 2/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>
#import "BKSessionController.h"
#import "downloaderAppDelegate.h"

@interface BTSender : NSObject <BKSessionControllerDelegate, GKPeerPickerControllerDelegate, UIAlertViewDelegate, GKSessionDelegate>

@property (nonatomic, retain) BKSessionController *sessionController;

+ (id)sharedInstance;

- (void)showAlert;

@end
