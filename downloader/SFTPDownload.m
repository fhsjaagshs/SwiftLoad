//
//  SFTPDownload.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 7/6/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "SFTPDownload.h"

@interface SFTPDownload ()

@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, strong) DLSFTPConnection *connection;

@end

@implementation SFTPDownload

+ (SFTPDownload *)downloadWithURL:(NSURL *)url username:(NSString *)username andPassword:(NSString *)password {
    return [[[self class]alloc]initWithURL:url username:username andPassword:password];
}

- (id)initWithURL:(NSURL *)url username:(NSString *)username andPassword:(NSString *)password {
    self = [super init];
    if (self) {
        self.URL = url;
        self.name = [_URL.path.lastPathComponent percentSanitize];
        self.connection = [[DLSFTPConnection alloc]initWithHostname:_URL.host username:username password:password];
    }
    return self;
}

- (void)stop {
    [_connection cancelAllRequests];
    [_connection disconnect];
    [super stop];
}

- (void)start {
    [super start];
    
    self.temporaryPath = getNonConflictingFilePathForPath([NSTemporaryDirectory() stringByAppendingPathComponent:self.name]);
    
    [_connection connectWithSuccessBlock:^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            @autoreleasepool {
                DLSFTPDownloadRequest *req = [[DLSFTPDownloadRequest alloc]initWithRemotePath:_URL.path localPath:self.temporaryPath resume:NO successBlock:^(DLSFTPFile *file, NSDate *startTime, NSDate *finishTime) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        @autoreleasepool {
                            [self showSuccess];
                        }
                    });
                } failureBlock:^(NSError *error) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        @autoreleasepool {
                            [self showFailure];
                        }
                    });
                } progressBlock:^(unsigned long long bytesReceived, unsigned long long bytesTotal) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        @autoreleasepool {
                            [self.delegate setProgress:((float)bytesReceived/(float)bytesTotal)];
                        }
                    });
                }];
                
                [_connection submitRequest:req];
            }
        });
    } failureBlock:^(NSError *error) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            @autoreleasepool {
                [self showFailure];
                [TransparentAlert showAlertWithTitle:@"SFTP Login Error" andMessage:error.localizedDescription.stringByCapitalizingFirstLetter];
            }
        });
    }];
}


@end
