//
//  DropboxUpload.m
//  Swift
//
//  Created by Nathaniel Symer on 8/3/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "DropboxUpload.h"

@interface DropboxUpload ()

@property (nonatomic, strong) NSString *localPath;

@end

@implementation DropboxUpload

+ (DropboxUpload *)uploadWithFile:(NSString *)file {
    return [[[self class]alloc]initWithFile:file];
}

- (instancetype)initWithFile:(NSString *)file {
    self = [super init];
    if (self) {
        self.localPath = file;
    }
    return self;
}

- (void)stop {
    [DroppinBadassBlocks cancel];
    [super stop];
}

- (void)start {
    [super start];
    [DroppinBadassBlocks loadMetadata:@"/" withCompletionBlock:^(DBMetadata *metadata, NSError *error) {
        
        if (error) {
            [self showFailure];
        } else {
            NSString *rev = nil;
            
            if (metadata.isDirectory) {
                for (DBMetadata *file in metadata.contents) {
                    if (file.isDirectory) {
                        continue;
                    }
                    
                    if ([file.filename isEqualToString:_localPath.lastPathComponent]) {
                        [[NetworkActivityController sharedController]show];
                        rev = file.rev;
                        break;
                    }
                }

                [DroppinBadassBlocks uploadFile:_localPath.lastPathComponent toPath:@"/" withParentRev:rev fromPath:_localPath withBlock:^(NSString *destPath, NSString *srcPath, DBMetadata *metadata, NSError *error) {
                    
                    if (error) {
                        [self showFailure];
                    } else {
                        [DroppinBadassBlocks loadSharableLinkForFile:metadata.path andCompletionBlock:^(NSString *link, NSString *path, NSError *error) {

                            if (error) {
                                [self showFailure];
                            } else {
                                [self showSuccess];
                                [[[TransparentAlert alloc]initWithTitle:[NSString stringWithFormat:@"Link For:\n%@",[path lastPathComponent]] message:link completionBlock:^(NSUInteger buttonIndex, UIAlertView *alertView) {
                                    if (buttonIndex == 1) {
                                        [[UIPasteboard generalPasteboard]setString:alertView.message];
                                    }
                                } cancelButtonTitle:@"OK" otherButtonTitles:@"Copy", nil]show];
                            }
                        }];
                    }
                    
                } andProgressBlock:^(CGFloat progress, NSString *destPath, NSString *scrPath) {
                    [self.delegate setProgress:progress];
                }];
            }
        }
    }];
}

@end
