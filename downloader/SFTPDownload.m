//
//  SFTPDownload.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 7/6/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "SFTPDownload.h"

@interface SFTPDownload ()

@property (nonatomic, retain) NSURL *URL;
@property (nonatomic, retain) DLSFTPConnection *connection;

@end

@implementation SFTPDownload

+ (SFTPDownload *)downloadWithURL:(NSURL *)url username:(NSString *)username andPassword:(NSString *)password {
    return [[[[self class]alloc]initWithURL:url username:username andPassword:password]autorelease];
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
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
            
            DLSFTPDownloadRequest *req = [[DLSFTPDownloadRequest alloc]initWithRemotePath:_URL.path localPath:getNonConflictingFilePathForPath([kDocsDir stringByAppendingPathComponent:self.fileName]) resume:NO successBlock:^(DLSFTPFile *file, NSDate *startTime, NSDate *finishTime) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    NSAutoreleasePool *poolTwo = [[NSAutoreleasePool alloc]init];
                    [self showSuccess];
                    NSLog(@"success");
                    [poolTwo release];
                });
            } failureBlock:^(NSError *error) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    NSAutoreleasePool *poolTwo = [[NSAutoreleasePool alloc]init];
                    [self showFailure];
                    [poolTwo release];
                });
            } progressBlock:^(unsigned long long bytesReceived, unsigned long long bytesTotal) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    NSAutoreleasePool *poolTwo = [[NSAutoreleasePool alloc]init];
                    [self.delegate setProgress:((float)bytesReceived/(float)bytesTotal)];
                    [poolTwo release];
                });
            }];
            
            [_connection submitRequest:req];
            
            [pool release];
        });
    } failureBlock:^(NSError *error) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
            [self showFailure];
            [TransparentAlert showAlertWithTitle:@"SFTP Login Error" andMessage:error.localizedDescription.stringByCapitalizingFirstLetter];
            [pool release];
        });
    }];
}

- (void)dealloc {
    [self setURL:nil];
    [self setConnection:nil];
    [super dealloc];
}

@end
