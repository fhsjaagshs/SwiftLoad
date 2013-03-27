//
//  webDAVViewController.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 2/7/12.
//  Copyright 2012 Nathaniel Symer. All rights reserved.
//

#import "webDAVViewController.h"

@implementation webDAVViewController

@synthesize urlLabel, onLabel, httpServer;

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
    self.onLabel.textAlignment = UITextAlignmentCenter;
    self.onLabel.backgroundColor = [UIColor clearColor];
    self.onLabel.textColor = [UIColor whiteColor];
    self.onLabel.text = @"WebDAV server is ON";
    self.onLabel.font = [UIFont boldSystemFontOfSize:iPad?28:23];
    self.onLabel.shadowColor = [UIColor darkGrayColor];
    self.onLabel.shadowOffset = CGSizeMake(-1, -1);
    [self.view addSubview:self.onLabel];
    
    UITextView *tf = [[[UITextView alloc]initWithFrame:iPad?CGRectMake(158, 235, 453, 83):CGRectMake(40, sanitizeMesurement(160), 240, 83)]autorelease];
    tf.text = @"Use a WebDAV client like CyberDuck or Interarchy to connect to the following URL using the non-SSL protocol:";
    tf.textColor = [UIColor whiteColor];
    tf.backgroundColor = [UIColor clearColor];
    tf.font = [UIFont systemFontOfSize:iPad?17:15];
    tf.editable = NO;
    tf.textAlignment = UITextAlignmentCenter;
    [self.view addSubview:tf];
    
    self.urlLabel = [[[UILabel alloc]initWithFrame:iPad?CGRectMake(20, 379, 728, 86):CGRectMake(0, sanitizeMesurement(283), screenBounds.size.width, 21)]autorelease];
    self.urlLabel.textColor = myCyan;
    self.urlLabel.backgroundColor = [UIColor clearColor];
    self.urlLabel.font = [UIFont boldSystemFontOfSize:iPad?31:18];
    self.urlLabel.shadowColor = [UIColor darkGrayColor];
    self.urlLabel.shadowOffset = CGSizeMake(-1, -1);
    self.urlLabel.textAlignment = UITextAlignmentCenter;
    [self.view addSubview:self.urlLabel];
    
    UITextView *btf = [[[UITextView alloc]initWithFrame:iPad?CGRectMake(158, 512, 453, 61):CGRectMake(40, sanitizeMesurement(326), 240, 50)]autorelease];
    btf.backgroundColor = [UIColor clearColor];
    btf.editable = NO;
    btf.textAlignment = UITextAlignmentCenter;
    btf.textColor = [UIColor whiteColor];
    btf.font = [UIFont systemFontOfSize:iPad?19:14];
    btf.text = @"This WebDAV server is only active as long as this screen is open.";
    [self.view addSubview:btf];
    
    [self performSelector:@selector(checkForNetworkChange) withObject:nil afterDelay:5.0];
    [self createServer];
}

- (void)killServer {
    [self.httpServer stop];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

- (void)createServer {
    if (![NetworkUtils isConnectedToWifi]) {
        return;
    }
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;

    self.httpServer = [[[HTTPServer alloc]init]autorelease];
    [self.httpServer setType:@"_http._tcp."];
    [self.httpServer setConnectionClass:[DAVConnection class]];
    [self.httpServer setPort:8080];
    [self.httpServer setName:[[UIDevice currentDevice]name]];
	[self.httpServer setDocumentRoot:kDocsDir];
    
    NSError *error;
    [self.httpServer start:&error];
	if (error != nil) {
        [self.urlLabel setText:@"Error starting server"];
        [self.onLabel setText:@"WebDAV server is OFF"];
	} else {
        NSString *rawIP = [NetworkUtils getIPAddress];
        if (rawIP.length == 0) {
            [self.urlLabel setText:@"Unable to establish server"];
            [self.onLabel setText:@"WebDAV server is OFF"];
        } else {
            [self.onLabel setText:@"WebDAV server is ON"];
            [self.urlLabel setText:[NSString stringWithFormat:@"http://%@:8080/",rawIP]];
        }
    }
}

- (void)checkForNetworkChange {
    if (![NetworkUtils isConnectedToWifi]) {
        [self.urlLabel setText:@"You are not connected to WiFi"];
        [self.onLabel setText:@"WebDAV server is OFF"];
        [self killServer];
        [self performSelector:@selector(checkForNetworkChange) withObject:nil afterDelay:10.0];
    } else if (!self.httpServer.isRunning) {
        [self createServer];
        [self performSelector:@selector(checkForNetworkChange) withObject:nil afterDelay:5.0];
    }
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
