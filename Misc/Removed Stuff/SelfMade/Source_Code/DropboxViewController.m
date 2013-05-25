//
//  DropboxViewController.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DropboxViewController.h"
#import "downloaderAppDelegate.h"
#import "CHDropboxSync.h"

@implementation DropboxViewController

@synthesize linkButton, switchMotherFucker;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (IBAction)toggleTimer:(id)sender {
    downloaderAppDelegate *appDelegate = (downloaderAppDelegate *)[[UIApplication sharedApplication]delegate];
    
    UISwitch *switchy = (UISwitch *)sender;
    if (switchy.on) {
        [appDelegate fireHourlyBackup];
    } else {
        [appDelegate cancelHourlyBackup];
    }
}

- (IBAction)close {
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)startSyncing {
    downloaderAppDelegate *appDelegate = (downloaderAppDelegate *)[[UIApplication sharedApplication]delegate];
    [appDelegate startSyncing];
}

- (IBAction)cancelSync {
    downloaderAppDelegate *appDelegate = (downloaderAppDelegate *)[[UIApplication sharedApplication]delegate];
    [appDelegate cancelSyncing];
}

- (IBAction)link {
    if (![[DBSession sharedSession]isLinked]) {
        [[DBSession sharedSession]linkFromController:self];
        [linkButton setTitle:@"Unlink"];
    } else {
        [[DBSession sharedSession]unlinkAll];
        [linkButton setTitle:@"Link"];
        CustomAlertView *avD = [[CustomAlertView alloc]initWithTitle:@"Account Unlinked" message:@"Your dropbox account has been unlinked." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [avD show];
        [avD release];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (![[DBSession sharedSession]isLinked]) {
        [linkButton setTitle:@"Link"];
    } else {
        [linkButton setTitle:@"Unlink"];
    }
    
    for (UIView *view in self.view.subviews) {
        if ([view isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)view;
            label.shadowColor = [UIColor darkGrayColor];
            label.shadowOffset = CGSizeMake(-1, -1);
        }
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    if (![[DBSession sharedSession]isLinked]) {
        [linkButton setTitle:@"Link"];
    } else {
        [linkButton setTitle:@"Unlink"];
    }
    downloaderAppDelegate *appDelegate = (downloaderAppDelegate *)[[UIApplication sharedApplication]delegate];
    switchMotherFucker.on = [appDelegate getSwitchState];
    [super viewWillAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    // release shit here
    [switchMotherFucker release];
    [linkButton release];
    [super dealloc];
}

@end
