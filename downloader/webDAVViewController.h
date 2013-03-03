//
//  webDAVViewController.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 2/7/12.
//  Copyright 2012 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface webDAVViewController : UIViewController

@property (nonatomic, retain) HTTPServer *httpServer;
@property (nonatomic, retain) UILabel *urlLabel;
@property (nonatomic, retain) UILabel *onLabel;

@end
