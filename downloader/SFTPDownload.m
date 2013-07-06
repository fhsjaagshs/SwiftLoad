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
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *password;
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
        self.username = username;
        self.password = password;
        self.fileName = _URL.path.lastPathComponent;
    }
    return self;
}

- (void)stop {
    [super stop];
    [_connection cancelAllRequests];
}

- (void)start {
    [super start];
    self.connection = [[DLSFTPConnection alloc]initWithHostname:_URL.host username:_username password:_password];
    [_connection connectWithSuccessBlock:^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
            DLSFTPDownloadRequest *req = [[DLSFTPDownloadRequest alloc]initWithRemotePath:_URL.path localPath:[kDocsDir stringByAppendingPathComponent:self.fileName] resume:NO successBlock:^(DLSFTPFile *file, NSDate *startTime, NSDate *finishTime) {
                [self showSuccess];
            } failureBlock:^(NSError *error) {
                [self showFailure];
            } progressBlock:^(unsigned long long bytesReceived, unsigned long long bytesTotal) {
                [self.delegate setProgress:(bytesReceived/bytesTotal)];
            }];
            
            [_connection submitRequest:req];
            
            [pool release];
        });
    } failureBlock:^(NSError *error) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
            [self showFailure];
            NSLog(@"Error: %@",error);
            [TransparentAlert showAlertWithTitle:@"SFTP Login Error" andMessage:@"There was an issue logging in via SFTP."]; // improve this later
            [pool release];
        });
    }];
}

- (void)dealloc {
    [self setURL:nil];
    [self setUsername:nil];
    [self setPassword:nil];
    [self setConnection:nil];
    [super dealloc];
}

@end
