//
//  DropboxDownload.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/30/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "DropboxDownload.h"
#import "DownloadingCell.h"

@interface DropboxDownload ()

@property (nonatomic, strong) NSString *path;

@end

@implementation DropboxDownload

+ (DropboxDownload *)downloadWithPath:(NSString *)path {
    return [[[[self class]alloc]initWithPath:path]autorelease];
}

- (id)initWithPath:(NSString *)path {
    self = [super init];
    if (self) {
        self.path = path;
        self.fileName = [path lastPathComponent];
    }
    return self;
}

- (void)stop {
    [super stop];
    [DroppinBadassBlocks cancel];
}

- (void)start {
    [super start];
    [DroppinBadassBlocks loadFile:_path intoPath:getNonConflictingFilePathForPath([kDocsDir stringByAppendingPathComponent:self.fileName]) withCompletionBlock:^(DBMetadata *metadata, NSError *error) {
        if (error) {
            [self showFailure];
        } else {
            [self showSuccess];
        }
    } andProgressBlock:^(CGFloat progress) {
        [self.delegate setProgress:progress];
    }];
}

- (void)dealloc {
    [self setPath:nil];
    [super dealloc];
}

@end
