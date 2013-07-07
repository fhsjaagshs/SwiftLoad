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
    [_request cancelRequest];
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
    
    NSString *path = getNonConflictingFilePathForPath([[kDocsDir stringByAppendingPathComponent:url.absoluteString.lastPathComponent]percentSanitize]);
    
    if (![[NSFileManager defaultManager]fileExistsAtPath:path]) {
        [[NSFileManager defaultManager]createFileAtPath:path contents:nil attributes:nil];
    }
    
    self.request = [SCRFTPRequest requestWithURL:url toDownloadFile:path];
    _request.username = _username;
    _request.password = _password;
    _request.delegate = self;
    _request.didFinishSelector = @selector(downloadFinished:);
    _request.didFailSelector = @selector(downloadFailed:);
    _request.willStartSelector = @selector(downloadWillStart:);
    _request.bytesReadSelector = @selector(bytesRead:);
    [_request startAsynchronous];
}

- (void)bytesRead:(SCRFTPRequest *)request {
    NSLog(@"%llu",_request.bytesRead/_request.fileSize);
    [self.delegate setProgress:((float)_request.bytesWritten/(float)_request.fileSize)];
}

- (void)downloadFinished:(SCRFTPRequest *)request {
    fireNotification(_url.absoluteString.lastPathComponent.percentSanitize);
    [self showSuccess];
}

- (void)downloadFailed:(SCRFTPRequest *)request {
    if ([_request.error.localizedDescription isEqualToString:@"FTP error 530"]) {
        [TransparentAlert showAlertWithTitle:@"Insecure Authorization Required" andMessage:@"The server requires authentication in order to download your file. Since FTP sends passwords in plain text, try using SFTP to download your file."];
        /*FTPLoginController *controller = [[[FTPLoginController alloc]initWithCompletionHandler:^(NSString *username, NSString *password, NSString *url) {
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
        [controller show];*/
    } else {
        NSLog(@"Request.error = %@",_request.error);
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
