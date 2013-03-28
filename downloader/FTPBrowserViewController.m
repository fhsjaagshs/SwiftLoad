//
//  FTPBrowserViewController.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 3/27/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "FTPBrowserViewController.h"
#import "ButtonBarView.h"

@interface FTPBrowserViewController ()

@end

@implementation FTPBrowserViewController

- (void)loadView {
    [super loadView];
    
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    
    self.view = [[[UIView alloc]initWithFrame:screenBounds]autorelease];
    self.view.backgroundColor = [UIColor clearColor];
    
    self.navBar = [[[CustomNavBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)]autorelease];
    self.navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[[UINavigationItem alloc]initWithTitle:@"/"]autorelease];
    topItem.leftBarButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)]autorelease];
    [self.navBar pushNavigationItem:topItem animated:YES];
    [self.view addSubview:self.navBar];
    [self.view bringSubviewToFront:self.navBar];
    
    ButtonBarView *bbv = [[[ButtonBarView alloc]initWithFrame:CGRectMake(0, 44, screenBounds.size.width, 44)]autorelease];
    bbv.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:bbv];
    
    self.homeButton = [[[CustomButton alloc]initWithFrame:iPad?CGRectMake(358, 4, 62, 36):CGRectMake(123, 4, 62, 36)]autorelease];
    [self.homeButton setTitle:@"Home" forState:UIControlStateNormal];
    [self.homeButton addTarget:self action:@selector(goHome) forControlEvents:UIControlEventTouchUpInside];
    self.homeButton.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    self.homeButton.titleLabel.shadowColor = [UIColor blackColor];
    self.homeButton.titleLabel.shadowOffset = CGSizeMake(0, -1);
    self.homeButton.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    [bbv addSubview:self.homeButton];
    [self.homeButton setHidden:YES];
    
    self.backButton = [[[CustomButton alloc]initWithFrame:iPad?CGRectMake(117, 4, 62, 36):CGRectMake(53, 4, 62, 37)]autorelease];
    [self.backButton setTitle:@"Back" forState:UIControlStateNormal];
    [self.backButton addTarget:self action:@selector(goBackDir) forControlEvents:UIControlEventTouchUpInside];
    self.backButton.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    self.backButton.titleLabel.shadowColor = [UIColor blackColor];
    self.backButton.titleLabel.shadowOffset = CGSizeMake(0, -1);
    self.backButton.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    [bbv addSubview:self.backButton];
    [self.backButton setHidden:YES];
    
    self.theTableView = [[[ShadowedTableView alloc]initWithFrame:CGRectMake(0, 88, screenBounds.size.width, screenBounds.size.height-88) style:UITableViewStylePlain]autorelease];
    self.theTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.theTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.theTableView.backgroundColor = [UIColor clearColor];
    self.theTableView.rowHeight = iPad?60:44;
    self.theTableView.dataSource = self;
    self.theTableView.delegate = self;
    self.theTableView.allowsSelectionDuringEditing = YES;
    [self.view addSubview:self.theTableView];
    
    PullToRefreshView *pull = [[PullToRefreshView alloc]initWithScrollView:self.theTableView];
    [pull setDelegate:self];
    [self.theTableView addSubview:pull];
    [pull release];
}

- (void)listFinished:(SCRFTPRequest *)request {
    self.filedicts = [[request.directoryContents mutableCopy]autorelease];
    NSLog(@"Directory Contents: %@",request.directoryContents);
    [self.theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    [request release];
}

- (void)listFailed:(SCRFTPRequest *)request {
    NSLog(@"Request Error: %@",request.error);
    [request release];
}

- (void)listWillStart:(SCRFTPRequest *)request {
    NSLog(@"starting");
}

- (void)listFilesInRemoteDirectory:(NSString *)url {
    FTPLoginController *controller = [[[FTPLoginController alloc]initWithCompletionHandler:^(NSString *username, NSString *password, NSString *url) {
        if ([username isEqualToString:@"cancel"]) {
            [[NSFileManager defaultManager]removeItemAtPath:[kDocsDir stringByAppendingPathComponent:[url lastPathComponent]] error:nil];
        } else {
            SCRFTPRequest *ftpRequest = [[SCRFTPRequest requestWithURLToListDirectory:[NSURL URLWithString:url]]retain];
            ftpRequest.delegate = self;
            ftpRequest.didFinishSelector = @selector(listFinished:);
            ftpRequest.didFailSelector = @selector(listFailed:);
            ftpRequest.willStartSelector = @selector(listWillStart:);
            [ftpRequest startRequest];
        }
    }]autorelease];
    [controller setType:FTPLoginControllerTypeLogin];
    [controller show];
}



@end
