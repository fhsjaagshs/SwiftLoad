//
//  FTPLoginController.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 3/24/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    FTPLoginControllerTypeUpload,
    FTPLoginControllerTypeDownload,
    FTPLoginControllerTypeLogin
} FTPLoginControllerType;

@interface FTPLoginController : TransparentAlert

- (id)initWithType:(FTPLoginControllerType)type andCompletionHandler:(void (^)(NSString *username, NSString *password, NSString *url))block;
- (void)setUrl:(NSString *)url isPredefined:(BOOL)isPredef;

@property (nonatomic, assign) SEL didMoveOnSelector;
@property (nonatomic, assign) id textFieldDelegate;
@property (nonatomic, assign, setter = setSFTP:) BOOL isSFTP;

@end
