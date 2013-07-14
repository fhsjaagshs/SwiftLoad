//
//  fileInfo.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 9/13/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface fileInfo : UIViewController <UITextFieldDelegate> 

@property (nonatomic, strong) UILabel *staticMD5Label;
@property (nonatomic, strong) UITextField *fileName;
@property (nonatomic, strong) UILabel *md5Field;
@property (nonatomic, strong) UILabel *moddateLabel;
@property (nonatomic, strong) UIBarButtonItem *revertButton;

@end
