//
//  SwiftGenericViewController.h
//  Swift
//
//  Created by Nathaniel Symer on 10/12/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SwiftGenericViewController : WhiteStatusbarViewController

@property (nonatomic, strong) NSString *openFile;

+ (instancetype)viewControllerWithFilepath:(NSString *)filepath;
+ (instancetype)viewControllerWhiteWithFilepath:(NSString *)filepath;

- (void)showActionSheetFromBarButtonItem:(UIBarButtonItem *)item withButtonTitles:(NSArray *)titles;
- (void)actionSheet:(UIActionSheet *)actionSheet selectedIndex:(NSUInteger)buttonIndex;

@end
