//
//  MyFilesViewController.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 8/11/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShadowedTableView.h"

@interface MyFilesViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, PullToRefreshViewDelegate, MBProgressHUDDelegate, UITextFieldDelegate, MFMailComposeViewControllerDelegate,  UIDocumentInteractionControllerDelegate> {
    CustomAlertView *av;
    UITextField *tv;
    float totalProgress;
}

// Copy/Cut/Paste
@property (nonatomic, retain) NSMutableArray *copiedList;
@property (nonatomic, retain) NSMutableArray *perspectiveCopiedList;
@property (nonatomic, assign) BOOL isCut;

@property (nonatomic, retain) UIDocumentInteractionController *docController;

@property (nonatomic, retain) NSMutableArray *filelist;
@property (nonatomic, retain) NSMutableArray *dirs;

@property (nonatomic, retain) IBOutlet UITableView *theTableView;
@property (nonatomic, retain) UIBarButtonItem *editButton;
@property (nonatomic, retain) IBOutlet CustomButton *backButton;
@property (nonatomic, retain) CustomButton *homeButton;
@property (nonatomic, retain) CustomNavBar *navBar;
@property (nonatomic, retain) CustomButton *copyAndPasteButton;

@property (nonatomic, retain) UIView *sideSwipeView;
@property (nonatomic, assign) UITableViewCell *sideSwipeCell;
@property (nonatomic, assign) UISwipeGestureRecognizerDirection sideSwipeDirection;
@property (nonatomic, assign) BOOL animatingSideSwipe;

@end
