//
//  SettingsView.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/6/12.
//  Copyright 2012 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "downloaderAppDelegate.h"

@interface SettingsView : UIViewController <DBSessionDelegate, DBRestClientDelegate>

@property (nonatomic, strong) UIButton *linkButton;

@end
