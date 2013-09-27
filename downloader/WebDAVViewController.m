//
//  webDAVViewController.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 2/7/12.
//  Copyright 2012 Nathaniel Symer. All rights reserved.
//

#import "WebDAVViewController.h"

@interface PasswdWebDAVConnection : DAVConnection

@end

@implementation PasswdWebDAVConnection

- (BOOL)isPasswordProtected:(NSString *)path {    
	return YES;
}

- (BOOL)useDigestAccessAuthentication {
	return YES;
}

- (NSString *)passwordForUser:(NSString *)username {
    NSDictionary *creds = [SimpleKeychain load:@"webdav_creds"];
    
    if ([creds[@"username"]isEqualToString:username]) {
        return creds[@"password"];
    }
	return nil;
}

@end

@interface WebDAVViewController ()

@property (nonatomic, strong) HTTPServer *httpServer;
@property (nonatomic, strong) UITextView *urlLabel;
@property (nonatomic, strong) UILabel *onLabel;

@end

@implementation WebDAVViewController

- (void)loadView {
    [super loadView];
    CGRect screenBounds = [[UIScreen mainScreen]bounds];
    
    UINavigationBar *navBar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 64)];
    navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"WebDAV Server"];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    [navBar pushNavigationItem:topItem animated:NO];
    [self.view addSubview:navBar];
    
    self.onLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 64, screenBounds.size.width, 100)];
    _onLabel.textAlignment = NSTextAlignmentCenter;
    _onLabel.backgroundColor = [UIColor clearColor];
    _onLabel.textColor = [UIColor blackColor];
    _onLabel.text = @"WebDAV server is ON";
    _onLabel.font = [UIFont boldSystemFontOfSize:23];
    [self.view addSubview:_onLabel];
    
    UITextView *btf = [[UITextView alloc]initWithFrame:CGRectMake(0, 180, screenBounds.size.width, 60)];
    btf.backgroundColor = [UIColor clearColor];
    btf.editable = NO;
    btf.textAlignment = NSTextAlignmentCenter;
    btf.textColor = [UIColor blackColor];
    btf.font = [UIFont systemFontOfSize:14];
    btf.scrollEnabled = NO;
    btf.text = @"This WebDAV server is only active as long as this screen is open.";
    [self.view addSubview:btf];
    
    self.urlLabel = [[UITextView alloc]initWithFrame:CGRectMake(0, 250, screenBounds.size.width, 30)];
    _urlLabel.textColor = [UIColor darkGrayColor];
    _urlLabel.backgroundColor = [UIColor clearColor];
    _urlLabel.font = [UIFont boldSystemFontOfSize:18];
    _urlLabel.textAlignment = NSTextAlignmentCenter;
    _urlLabel.editable = NO;
    _urlLabel.scrollEnabled = NO;
    [self.view addSubview:_urlLabel];
    
    NSString *htmlString = @"<center style=\"font-family: Helvetica; font-size:15px;\"><strong>Server</strong> Above IP address<br /><strong>Port</strong> 8080<br /><strong>SSL</strong> NO<br /><strong>Username</strong> See In-App Settings<br /><strong>Password</strong> See In-App Settings</center>";
    
    UITextView *textView = [[UITextView alloc]initWithFrame:CGRectMake(0, screenBounds.size.height-130, screenBounds.size.width, 130)];
    textView.attributedText = [[NSAttributedString alloc]initWithData:[htmlString dataUsingEncoding:NSUTF8StringEncoding] options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: [NSNumber numberWithInt:NSUTF8StringEncoding]} documentAttributes:nil error:nil];
    textView.backgroundColor = [UIColor clearColor];
    textView.editable = NO;
    [self.view addSubview:textView];
    
    [self createServer];
}

- (void)killServer {
    [_httpServer stop];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    _onLabel.text = @"WebDAV server is OFF";
}

- (void)createServer {
    if (![NetworkUtils isConnectedToWifi]) {
        _onLabel.text = @"WebDAV server is OFF";
        _urlLabel.text = @"You are not connected to WiFi";
        [self killServer];
    }
    
    if (_httpServer) {
        return;
    }

    self.httpServer = [[HTTPServer alloc]init];
    [_httpServer setType:@"_http._tcp."];
    [_httpServer setConnectionClass:[PasswdWebDAVConnection class]];
    [_httpServer setPort:8080];
    [_httpServer setName:[[UIDevice currentDevice]name]];
	[_httpServer setDocumentRoot:kDocsDir];
    
    NSError *error;
    [_httpServer start:&error];
	if (error != nil) {
        _urlLabel.text = @"Error starting server";
        _onLabel.text = @"WebDAV server is OFF";
	} else {
        NSString *rawIP = [NetworkUtils getIPAddress];
        if (rawIP.length == 0) {
            _urlLabel.text = @"Unable to establish server";
            _onLabel.text = @"WebDAV server is OFF";
        } else {
            _onLabel.text = @"WebDAV server is ON";
            [self.urlLabel setText:[NSString stringWithFormat:@"http://%@:8080/",rawIP]];
            [UIApplication sharedApplication].idleTimerDisabled = YES;
        }
    }
    [self performSelector:@selector(createServer) withObject:nil afterDelay:_httpServer.isRunning?30.0:5.0];
}

- (void)close {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self killServer];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
