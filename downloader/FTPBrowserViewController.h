//
//  FTPBrowserViewController.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 3/27/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FTPBrowserViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, PullToRefreshViewDelegate>

@property (nonatomic, retain) ShadowedTableView *theTableView;
@property (nonatomic, retain) CustomButton *backButton;
@property (nonatomic, retain) CustomButton *homeButton;
@property (nonatomic, retain) CustomNavBar *navBar;

@property (nonatomic, retain) NSString *currentFTPURL;
@property (nonatomic, retain) NSMutableArray *filedicts;

@end
