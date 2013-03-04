//
//  BlockExtensions.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 3/4/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <MessageUI/MessageUI.h>

@interface MFMailComposeViewController (BlockExtensions) <MFMailComposeViewControllerDelegate>

- (id)initWithCompletionHandler:(void (^)(MFMailComposeViewController *controller, MFMailComposeResult result, NSError *error))block;

@end
