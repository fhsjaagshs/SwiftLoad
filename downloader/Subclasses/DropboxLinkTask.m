//
//  DropboxLinkTask.m
//  Swift
//
//  Created by Nathaniel Symer on 8/6/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "DropboxLinkTask.h"

@interface DropboxLinkTask ()

@property (nonatomic, strong) NSString *filePath;

@end

@implementation DropboxLinkTask

+ (DropboxLinkTask *)taskWithFilepath:(NSString *)filepath {
    return [[[self class]alloc]initWithFilepath:filepath];
}

- (instancetype)initWithFilepath:(NSString *)filepath {
    self = [super init];
    if (self) {
        self.name = filepath.lastPathComponent;
        self.filePath = filepath;
    }
    return self;
}

- (void)stop {
    [[NetworkActivityController sharedController]hideIfPossible];
    [DroppinBadassBlocks cancelShareableLinkLoadWithDropboxPath:_filePath];
    [super stop];
}

- (void)showFailure {
    [[NetworkActivityController sharedController]hideIfPossible];
    [super showFailure];
}

- (void)showSuccess {
    [[NetworkActivityController sharedController]hideIfPossible];
    fireNotification(self.name);
    [super showSuccess];
}

- (NSString *)verb {
    return @"Loading Link";
}

- (void)start {
    [[NetworkActivityController sharedController]show];
    [super start];
    
    [DroppinBadassBlocks loadSharableLinkForFile:_filePath andCompletionBlock:^(NSString *link, NSString *path, NSError *error) {
        if (error) {
            [self showFailure];
        } else {
            [self showSuccess];
            [[[TransparentAlert alloc]initWithTitle:[NSString stringWithFormat:@"Link For:\n%@",path.lastPathComponent] message:link completionBlock:^(NSUInteger buttonIndex, UIAlertView *alertView) {
                if (buttonIndex == 1) {
                    [[UIPasteboard generalPasteboard]setString:alertView.message];
                }
            } cancelButtonTitle:@"OK" otherButtonTitles:@"Copy", nil]show];
        }
    }];
}

@end
