//
//  FTPLoginController.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 3/24/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "CustomAlertView.h"

typedef enum {
    FTPLoginControllerTypeUpload,
    FTPLoginControllerTypeDownload,
    FTPLoginControllerTypeLogin
} FTPLoginControllerType;

@interface FTPLoginController : TransparentAlert

- (void)setType:(FTPLoginControllerType)type;
- (id)initWithCompletionHandler:(void (^)(NSString *username, NSString *password, NSString *url))block;
- (void)setUrl:(NSString *)url isPredefined:(BOOL)isPredef;

@property (nonatomic, assign) SEL didMoveOnSelector;
@property (nonatomic, assign) id textFieldDelegate;

@end
