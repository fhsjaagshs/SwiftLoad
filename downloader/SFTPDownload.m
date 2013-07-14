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
        self.fileName = _URL.path.lastPathComponent;
        self.connection = [[DLSFTPConnection alloc]initWithHostname:_URL.host username:username password:password];
    }
    return self;
}

- (void)stop {
    [super stop];
    [_connection cancelAllRequests];
}

- (void)start {
    [super start];
    [_connection connectWithSuccessBlock:^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            @autoreleasepool {
            
                __weak NSString *filePath = getNonConflictingFilePathForPath([NSTemporaryDirectory() stringByAppendingPathComponent:self.fileName]);
                
                DLSFTPDownloadRequest *req = [[DLSFTPDownloadRequest alloc]initWithRemotePath:_URL.path localPath:filePath resume:NO successBlock:^(DLSFTPFile *file, NSDate *startTime, NSDate *finishTime) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        @autoreleasepool {
                            [self showSuccess];
                            [[NSFileManager defaultManager]moveItemAtPath:filePath toPath:getNonConflictingFilePathForPath([kDocsDir stringByAppendingPathComponent:self.fileName]) error:nil];
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
