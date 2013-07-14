//
//  WebDAVCredsPrompt.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 7/9/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "TransparentAlert.h"

@protocol WebDAVCredsPromptCredsDelegate;

@interface WebDAVCredsPrompt : TransparentAlert

@property (nonatomic, weak) id<WebDAVCredsPromptCredsDelegate> credsDelegate;

- (id)initWithCredsDelegate:(id<WebDAVCredsPromptCredsDelegate>)delegate;

@end

@protocol WebDAVCredsPromptCredsDelegate <NSObject>

- (void)credsWereSaved;

@end