//
//  webDAVHelp.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 2/8/12.
//  Copyright 2012 Nathaniel Symer. All rights reserved.
//

#import "webDAVHelp.h"

@implementation webDAVHelp

- (void)loadView {
    [super loadView];
    BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    self.view = [StyleFactory backgroundView];
    
    UINavigationBar *navBar = [[[ShadowedNavBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)]autorelease];
    navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"WebDAV Setup"];
    topItem.leftBarButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)]autorelease];
    [navBar pushNavigationItem:topItem animated:NO];
    [self.view addSubview:navBar];
    [self.view bringSubviewToFront:navBar];
    [topItem release];
    
    UITextView *textView = [[[UITextView alloc]initWithFrame:CGRectMake(0, screenBounds.size.height-(iPad?200:200), screenBounds.size.width, iPad?200:150)]autorelease];
    textView.text = @"Server: IP address of iPhone\nPort: 8080\nConnection type: Non-SSL WebDAV\nUsername & Password: What you set in the previous window";
    textView.backgroundColor = [UIColor clearColor];
    textView.textColor = [UIColor blackColor];
    textView.font = [UIFont boldSystemFontOfSize:18];
    textView.textAlignment = UITextAlignmentCenter;
    textView.editable = NO;
    [self.view addSubview:textView];
    
    UIImageView *imageView = [[[UIImageView alloc]initWithFrame:iPad?CGRectMake(110, 131, 549, 287):CGRectMake(18, sanitizeMesurement(81), 285, 150)]autorelease];
    imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"config" ofType:@"png"]];
    [self.view addSubview:imageView];
}

- (void)close {
    [self dismissModalViewControllerAnimated:YES];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    NSLog(@"%@ dealloc'd", NSStringFromClass([self class]));
    [super dealloc];
}

@end
