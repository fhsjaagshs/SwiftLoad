//
//  DropboxDownload.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/30/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "DropboxDownload.h"

@interface DropboxDownload ()

@property (nonatomic, strong) NSString *path;

@end

@implementation DropboxDownload

+ (DropboxDownload *)downloadWithPath:(NSString *)path {
    return [[[self class]alloc]initWithPath:path];
}

- (id)initWithPath:(NSString *)path {
    self = [super init];
    if (self) {
        self.path = path;
        self.name = path.lastPathComponent;
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(dropboxAuthenticationSucceeded) name:@"db_auth_success" object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(dropboxAuthenticationFailed) name:@"db_auth_failure" object:nil];
    }
    return self;
}

- (void)dropboxAuthenticationSucceeded {
    [self carryOutDownload];
}

- (void)dropboxAuthenticationFailed {
    [self showFailure];
}

- (void)stop {
    [DroppinBadassBlocks cancelDownloadWithDropboxPath:_path];
    [super stop];
}

- (void)carryOutDownload {
    self.temporaryPath = deconflictPath([NSTemporaryDirectory() stringByAppendingPathComponent:self.name]);
    [DroppinBadassBlocks loadFile:_path intoPath:self.temporaryPath withCompletionBlock:^(DBMetadata *metadata, NSError *error) {
        if (error) {
            [self showFailure];
        } else {
            [self showSuccess];
        }
    } andProgressBlock:^(float progress) {
        if (self.delegate) {
            [self.delegate setProgress:progress];
        }
    }];
}

- (void)start {
    [super start];
    if ([[DBSession sharedSession]isLinked]) {
        [self carryOutDownload];
    } else {
        [AppDelegate disableStyling];
        [[DBSession sharedSession]linkFromController:[UIViewController topViewController]];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end
