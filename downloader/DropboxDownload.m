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
    }
    return self;
}

- (void)stop {
    [DroppinBadassBlocks cancel];
    [super stop];
}

- (void)start {
    [super start];
    [DroppinBadassBlocks loadFile:_path intoPath:getNonConflictingFilePathForPath([NSTemporaryDirectory() stringByAppendingPathComponent:self.name]) withCompletionBlock:^(DBMetadata *metadata, NSError *error) {
        if (error) {
            [self showFailure];
        } else {
            [self showSuccess];
        }
    } andProgressBlock:^(CGFloat progress) {
        if (self.delegate) {
            [self.delegate setProgress:progress];
        }
    }];
}

@end
