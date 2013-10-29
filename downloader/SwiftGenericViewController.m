//
//  SwiftGenericViewController.m
//  Swift
//
//  Created by Nathaniel Symer on 10/12/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "SwiftGenericViewController.h"

@interface SwiftGenericViewController () <UIActionSheetDelegate>

@property (nonatomic, strong) UIActionSheet *actionSheet;

@end

@implementation SwiftGenericViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UINavigationBar appearance]setBackgroundColor:[[UINavigationBar appearance].barTintColor colorWithAlphaComponent:0.9f]];
    [[UIToolbar appearance]setBackgroundColor:[[UIToolbar appearance].barTintColor colorWithAlphaComponent:0.9f]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[UINavigationBar appearance]setBackgroundColor:nil];
    [[UIToolbar appearance]setBackgroundColor:nil];
}

+ (instancetype)viewControllerWithFilepath:(NSString *)filepath {
    return [[[self class]alloc]initWithFilepath:filepath];
}

+ (instancetype)viewControllerWhiteWithFilepath:(NSString *)filepath {
    SwiftGenericViewController *ret = [[[self class]alloc]initWithFilepath:filepath];
    ret.view.backgroundColor = [UIColor whiteColor];
    ret.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    return ret;
}

- (instancetype)initWithFilepath:(NSString *)filepath {
    self = [super init];
    if (self) {
        // ORDER IS IMPORTANT
        self.openFile = filepath;
        self.view.backgroundColor = [UIColor clearColor]; // calls loadView
        self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    }
    return self;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self actionSheet:actionSheet selectedIndex:buttonIndex];
    self.actionSheet = nil;
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    self.actionSheet = nil;
}

- (void)actionSheet:(UIActionSheet *)actionSheet selectedIndex:(NSUInteger)buttonIndex {
    // subclasses should implement this
}

- (void)showActionSheetFromBarButtonItem:(UIBarButtonItem *)item withButtonTitles:(NSArray *)titles {
    if (_actionSheet && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [_actionSheet dismissWithClickedButtonIndex:_actionSheet.cancelButtonIndex animated:YES];
        self.actionSheet = nil;
        return;
    }

    self.actionSheet = [[UIActionSheet alloc]initWithTitle:_openFile.lastPathComponent delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];

    for (NSString *title in titles) {
        [_actionSheet addButtonWithTitle:title];
    }
    
    [_actionSheet addButtonWithTitle:@"Cancel"];
    _actionSheet.cancelButtonIndex = _actionSheet.numberOfButtons-1;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [_actionSheet showFromBarButtonItem:item animated:YES];
    } else {
        [_actionSheet showInView:self.view];
    }
}

@end
