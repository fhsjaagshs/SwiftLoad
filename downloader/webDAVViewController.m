//
//  webDAVViewController.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 2/7/12.
//  Copyright 2012 Nathaniel Symer. All rights reserved.
//

#import "webDAVViewController.h"

@implementation webDAVViewController

- (void)loadView {
    [super loadView];
    BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    self.view = [[[HatchedView alloc]initWithFrame:screenBounds]autorelease];
    
    CustomNavBar *navBar = [[[CustomNavBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)]autorelease];
    navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"WebDAV Server"];
    topItem.leftBarButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)]autorelease];
    topItem.rightBarButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"Help" style:UIBarButtonItemStyleBordered target:self action:@selector(showHelp)]autorelease];
    [navBar pushNavigationItem:topItem animated:NO];
    [self.view addSubview:navBar];
    [self.view bringSubviewToFront:navBar];
    [topItem release];
    
    self.onLabel = [[[UILabel alloc]initWithFrame:iPad?CGRectMake(234, 100, 300, 83):CGRectMake(0, sanitizeMesurement(44), screenBounds.size.width, 91)]autorelease];
    _onLabel.textAlignment = UITextAlignmentCenter;
    _onLabel.backgroundColor = [UIColor clearColor];
    _onLabel.textColor = [UIColor whiteColor];
    _onLabel.text = @"WebDAV server is ON";
    _onLabel.font = [UIFont boldSystemFontOfSize:iPad?28:23];
    _onLabel.shadowColor = [UIColor darkGrayColor];
    _onLabel.shadowOffset = CGSizeMake(-1, -1);
    [self.view addSubview:_onLabel];
    
    UITextView *tf = [[[UITextView alloc]initWithFrame:iPad?CGRectMake(158, 235, 453, 83):CGRectMake(40, sanitizeMesurement(160), 240, 83)]autorelease];
    tf.text = @"Use a WebDAV client like CyberDuck or Interarchy to connect to the following URL using the non-SSL protocol:";
    tf.textColor = [UIColor whiteColor];
    tf.backgroundColor = [UIColor clearColor];
    tf.font = [UIFont systemFontOfSize:iPad?17:15];
    tf.editable = NO;
    tf.textAlignment = UITextAlignmentCenter;
    [self.view addSubview:tf];
    
    self.urlLabel = [[[UILabel alloc]initWithFrame:iPad?CGRectMake(20, 379, 728, 86):CGRectMake(0, sanitizeMesurement(283), screenBounds.size.width, 21)]autorelease];
    _urlLabel.textColor = myCyan;
    _urlLabel.backgroundColor = [UIColor clearColor];
    _urlLabel.font = [UIFont boldSystemFontOfSize:iPad?31:18];
    _urlLabel.shadowColor = [UIColor darkGrayColor];
    _urlLabel.shadowOffset = CGSizeMake(-1, -1);
    _urlLabel.textAlignment = UITextAlignmentCenter;
    [self.view addSubview:_urlLabel];
    
    UITextView *btf = [[[UITextView alloc]initWithFrame:iPad?CGRectMake(158, 512, 453, 61):CGRectMake(40, sanitizeMesurement(326), 240, 50)]autorelease];
    btf.backgroundColor = [UIColor clearColor];
    btf.editable = NO;
    btf.textAlignment = UITextAlignmentCenter;
    btf.textColor = [UIColor whiteColor];
    btf.font = [UIFont systemFontOfSize:iPad?19:14];
    btf.text = @"This WebDAV server is only active as long as this screen is open.";
    [self.view addSubview:btf];
    
    [self checkForNetworkChange];
}

- (void)killServer {
    [self.httpServer stop];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

- (void)createServer {
    if (![NetworkUtils isConnectedToWifi]) {
        return;
    }
    
    if (_httpServer.isRunning) {
        return;
    }
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;

    self.httpServer = [[[HTTPServer alloc]init]autorelease];
    [_httpServer setType:@"_http._tcp."];
    [_httpServer setConnectionClass:[DAVConnection class]];
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
        }
    }
}

- (void)checkForNetworkChange {
    if (![NetworkUtils isConnectedToWifi]) {
        _urlLabel.text = @"You are not connected to WiFi";
        _onLabel.text = @"WebDAV server is OFF";
        [self killServer];
    } else if (!_httpServer.isRunning) {
        [self createServer];
    }
    
    [self performSelector:@selector(checkForNetworkChange) withObject:nil afterDelay:5.0];
}

- (void)close {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkForNetworkChange) object:nil];
    [self killServer];
    [self dismissModalViewControllerAnimated:YES];
}

- (void)showHelp {
    webDAVHelp *wdh = [webDAVHelp viewController];
    wdh.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentModalViewController:wdh animated:YES];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [self setHttpServer:nil];
    [self setUrlLabel:nil];
    [self setOnLabel:nil];
    NSLog(@"%@ dealloc'd", NSStringFromClass([self class]));
    [super dealloc];
}

@end
