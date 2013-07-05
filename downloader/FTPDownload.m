//
//  FTPDowload.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 7/4/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "FTPDownload.h"

@interface FTPDownload ()

@property (nonatomic, retain) SCRFTPRequest *request;

@end

@implementation FTPDownload

+ (FTPDownload *)downloadWithURL:(NSURL *)aURL {
    return [[[[self class]alloc]initWithURL:aURL]autorelease];
}

- (id)initWithURL:(NSURL *)aUrl {
    self = [super init];
    if (self) {
        self.url = aUrl;
    }
    return self;
}

- (void)stop {
    [super stop];
}

- (void)start {
    [super start];
    
    if (_username.length == 0) {
        self.username = @"anonymous";
        self.password = @"";
    }
    
    [self downloadFileUsingFtp:_url withUsername:_username andPassword:_password];
}

- (void)downloadFileUsingFtp:(NSURL *)url withUsername:(NSString *)username andPassword:(NSString *)password {
    self.username = username;
    self.password = password;
    
    self.request = [SCRFTPRequest requestWithURL:url toDownloadFile:getNonConflictingFilePathForPath([[kDocsDir stringByAppendingPathComponent:url.absoluteString.lastPathComponent]percentSanitize])];
    _request.username = _username;
    _request.password = _password;
    _request.delegate = self;
    _request.didFinishSelector = @selector(downloadFinished:);
    _request.didFailSelector = @selector(downloadFailed:);
    _request.willStartSelector = @selector(downloadWillStart:);
    [_request startRequest];
}

- (void)downloadFinished:(SCRFTPRequest *)request {
    fireNotification(_url.absoluteString.lastPathComponent.percentSanitize);
    [self showSuccess];
}

- (void)downloadFailed:(SCRFTPRequest *)request {
    if ([_request.error.localizedDescription isEqualToString:@"FTP error 530"]) {
        FTPLoginController *controller = [[[FTPLoginController alloc]initWithCompletionHandler:^(NSString *username, NSString *password, NSString *url) {
            if ([username isEqualToString:@"cancel"]) {
                [[NSFileManager defaultManager]removeItemAtPath:[kDocsDir stringByAppendingPathComponent:[url lastPathComponent]] error:nil];
            } else {
                self.username = username;
                self.password = password;
                _request.username = _username;
                _request.password = _password;
                [_request startRequest];
            }
        }]autorelease];
        [controller setUrl:_url.absoluteString isPredefined:YES];
        [controller setType:FTPLoginControllerTypeDownload];
        [controller show];
    } else {
        [self showFailure];
    }
}

- (void)downloadWillStart:(SCRFTPRequest *)request {
    self.fileName = [[request.ftpURL.absoluteString lastPathComponent]stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (void)dealloc {
    [self setUsername:nil];
    [self setPassword:nil];
    [self setUrl:nil];
    [self setRequest:nil];
    [super dealloc];
}

@end
