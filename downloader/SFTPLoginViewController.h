//
//  SFTPLoginViewController.h
//  Swift
//
//  Created by Nathaniel Symer on 9/23/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SFTPLoginViewController : UIViewController

@property (nonatomic, copy) void(^loginBlock)(NSString *url, NSString *username, NSString *password);
@property (nonatomic, copy) void(^cancellationBlock)(void);

@end
