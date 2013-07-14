//
//  webDAVViewController.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 2/7/12.
//  Copyright 2012 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface webDAVViewController : UIViewController

@property (nonatomic, strong) HTTPServer *httpServer;
@property (nonatomic, strong) UILabel *urlLabel;
@property (nonatomic, strong) UILabel *onLabel;

@end
