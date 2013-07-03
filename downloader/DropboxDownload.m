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
    [DroppinBadassBlocks cancel];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.complete = YES;
    self.succeeded = NO;
    self.fileName = nil;
}

- (void)start {
    [[NSNotificationCenter defaultCenter]postNotificationName:kDownloadChanged object:self];
    self.complete = NO;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [[BGProcFactory sharedFactory]startProcForKey:@"dropbox_download" andExpirationHandler:^{
        [self stop];
    }];
    
    [DroppinBadassBlocks loadFile:_path intoPath:getNonConflictingFilePathForPath([kDocsDir stringByAppendingPathComponent:self.fileName]) withCompletionBlock:^(DBMetadata *metadata, NSError *error) {
        [[BGProcFactory sharedFactory]endProcForKey:@"dropbox_download"];
        self.complete = YES;
        if (error) {
            self.succeeded = NO;
            [self showFailure];
        } else {
            self.succeeded = YES;
            [self showSuccessForFilename:self.fileName];
        }
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [self performSelector:@selector(clearOutMyself) withObject:nil afterDelay:0.6f];
        
    } andProgressBlock:^(CGFloat progress) {
        [self.delegate setProgress:progress];
    }];
}

- (void)showFailure {
    [self.delegate drawRed];
}

- (void)showSuccessForFilename:(NSString *)fileName {
    if (fileName.length > 14) {
        fileName = [[fileName substringToIndex:11]stringByAppendingString:@"..."];
    }
    
    UILocalNotification *notification = [[UILocalNotification alloc]init];
    notification.fireDate = [NSDate date];
    notification.alertBody = [NSString stringWithFormat:@"Finished downloading: %@",fileName];
    notification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication]presentLocalNotificationNow:notification];
    [notification release];
    
    [self.delegate drawGreen];
}

- (void)clearOutMyself {
    [self.delegate reset];
    [[Downloads sharedDownloads]removeDownload:self];
    [[NSNotificationCenter defaultCenter]postNotificationName:kDownloadChanged object:self];
}

- (void)dealloc {
    [self setPath:nil];
    [super dealloc];
}

@end
