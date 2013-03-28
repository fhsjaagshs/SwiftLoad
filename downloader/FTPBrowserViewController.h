//
//  FTPBrowserViewController.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 3/27/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FTPBrowserViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, PullToRefreshViewDelegate>

- (id)initWithURL:(NSString *)ftpurl;

@end
