//
//  fileInfo.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 9/13/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface fileInfo : UIViewController <UITextFieldDelegate> 

@property (nonatomic, retain) UILabel *staticMD5Label;
@property (nonatomic, retain) UITextField *fileName;
@property (nonatomic, retain) UILabel *md5Field;
@property (nonatomic, retain) UILabel *moddateLabel;
@property (nonatomic, retain) UIBarButtonItem *revertButton;

@end
