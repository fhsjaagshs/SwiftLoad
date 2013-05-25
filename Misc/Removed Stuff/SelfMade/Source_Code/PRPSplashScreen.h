//
//  PRPSplashScreen.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 12/26/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PRPSplashScreenDelegate;

@interface PRPSplashScreen : UIViewController {}

@property (nonatomic, assign) IBOutlet id<PRPSplashScreenDelegate> delegate;

@end


@protocol PRPSplashScreenDelegate <NSObject>

@optional 
- (void)splashScreenDidAppear:(PRPSplashScreen *)splashScreen;
/*- (void)splashScreenWillDisappear:(PRPSplashScreen *)splashScreen;
- (void)splashScreenDidDisappear:(PRPSplashScreen *)splashScreen;*/

@end

