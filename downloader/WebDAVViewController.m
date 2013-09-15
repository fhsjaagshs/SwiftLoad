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
@property (nonatomic, strong) UILabel *urlLabel;
@property (nonatomic, strong) UILabel *onLabel;

@end

@implementation WebDAVViewController

- (void)loadView {
    [super loadView];
    BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    
    UINavigationBar *navBar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)];
    navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"WebDAV Server"];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Help" style:UIBarButtonItemStyleBordered target:self action:@selector(showHelp)];
    [navBar pushNavigationItem:topItem animated:NO];
    [self.view addSubview:navBar];
    [self.view bringSubviewToFront:navBar];
    
    self.onLabel = [[UILabel alloc]initWithFrame:iPad?CGRectMake(234, 100, 300, 83):CGRectMake(0, sanitizeMesurement(44), screenBounds.size.width, 91)];
    _onLabel.textAlignment = NSTextAlignmentCenter;
    _onLabel.backgroundColor = [UIColor clearColor];
    _onLabel.textColor = [UIColor blackColor];
    _onLabel.text = @"WebDAV server is ON";
    _onLabel.font = [UIFont boldSystemFontOfSize:iPad?28:23];
    [self.view addSubview:_onLabel];
    
    UITextView *tf = [[UITextView alloc]initWithFrame:iPad?CGRectMake(158, 235, 453, 83):CGRectMake(40, sanitizeMesurement(160), 240, 83)];
    tf.text = @"Use a WebDAV client like CyberDuck or Interarchy to connect to the following URL using the non-SSL protocol:";
    tf.textColor = [UIColor blackColor];
    tf.backgroundColor = [UIColor clearColor];
    tf.font = [UIFont systemFontOfSize:iPad?17:15];
    tf.editable = NO;
    tf.textAlignment = NSTextAlignmentCenter;
    tf.scrollEnabled = NO;
    [self.view addSubview:tf];
    
    self.urlLabel = [[UILabel alloc]initWithFrame:iPad?CGRectMake(20, 379, 728, 86):CGRectMake(0, sanitizeMesurement(283), screenBounds.size.width, 21)];
    _urlLabel.textColor = [UIColor darkGrayColor];
    _urlLabel.backgroundColor = [UIColor clearColor];
    _urlLabel.font = [UIFont boldSystemFontOfSize:iPad?31:18];
    _urlLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_urlLabel];
    
    UITextView *btf = [[UITextView alloc]initWithFrame:iPad?CGRectMake(158, 512, 453, 61):CGRectMake(40, sanitizeMesurement(326), 240, 50)];
    btf.backgroundColor = [UIColor clearColor];
    btf.editable = NO;
    btf.textAlignment = NSTextAlignmentCenter;
    btf.textColor = [UIColor blackColor];
    btf.font = [UIFont systemFontOfSize:iPad?19:14];
    btf.scrollEnabled = NO;
    btf.text = @"This WebDAV server is only active as long as this screen is open.";
    [self.view addSubview:btf];
    
    [self createServer];
    
    [self adjustViewsForiOS7];
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

- (void)showHelp {
    [self presentViewController:[WebDAVHelpViewController viewControllerWhite] animated:YES completion:nil];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
