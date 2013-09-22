//
//  FTPLoginController.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 3/24/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    SFTPLoginControllerTypeUpload,
    SFTPLoginControllerTypeDownload,
    SFTPLoginControllerTypeLogin
} SFTPLoginControllerType;

@interface SFTPLoginController : UIAlertView

- (id)initWithType:(SFTPLoginControllerType)type andCompletionHandler:(void (^)(NSString *username, NSString *password, NSString *url))block;
- (void)setUrl:(NSString *)url isPredefined:(BOOL)isPredef;

@property (nonatomic, assign) SEL didMoveOnSelector;
@property (nonatomic, weak) id textFieldDelegate;

@end
