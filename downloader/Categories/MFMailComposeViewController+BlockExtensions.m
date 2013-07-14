//
//  BlockExtensions.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 3/4/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "MFMailComposeViewController+BlockExtensions.h"
#import <objc/runtime.h>

@implementation MFMailComposeViewController (BlockExtensions)

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    void (^block)(MFMailComposeViewController *controller, MFMailComposeResult result, NSError *error) = objc_getAssociatedObject(self, "blockCallbackMail");
    block(controller, result, error);
    //Block_release(block);
}

- (id)initWithCompletionHandler:(void (^)(MFMailComposeViewController *controller, MFMailComposeResult result, NSError *error))block {
    self = [super init];
    if (self) {
        objc_setAssociatedObject(self, "blockCallbackMail", [block copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        self.mailComposeDelegate = self;
    }
    return self;
}

@end

@implementation MFMessageComposeViewController (BlockExtensions)

- (id)initWithCompletionHandler:(void (^)(MFMessageComposeViewController *controller, MessageComposeResult result))block {
    self = [super init];
    if (self) {
        objc_setAssociatedObject(self, "blockCallbackMessage", [block copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        self.messageComposeDelegate = self;
    }
    return self;
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    void (^block)(MFMessageComposeViewController *controller, MessageComposeResult result) = objc_getAssociatedObject(self, "blockCallbackMessage");
    block(controller, result);
   // Block_release(block);
}


@end
