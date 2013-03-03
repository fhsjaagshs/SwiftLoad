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

    int indexOfCheckmark;

    float totalProgress;
    MBProgressHUD *HUDZ;
}

// Copy/Cut/Paste
@property (nonatomic, retain) NSMutableArray *copiedList;
@property (nonatomic, retain) NSMutableArray *perspectiveCopiedList;
@property (nonatomic, assign) BOOL isCut;

@property (nonatomic, retain) UIDocumentInteractionController *docController;

@property (nonatomic, retain) NSString *movingFileFirst;
@property (nonatomic, retain) NSString *pastingPath;

@property (nonatomic, retain) NSMutableArray *filelist;
@property (nonatomic, retain) NSMutableArray *dirs;

@property (nonatomic, retain) IBOutlet UITableView *theTableView;
@property (nonatomic, retain) IBOutlet UITextField *folderPathTitle;  
@property (nonatomic, retain) IBOutlet UIBarButtonItem *editButton;
@property (nonatomic, retain) IBOutlet CustomButton *mtrButton;
@property (nonatomic, retain) IBOutlet CustomButton *backButton;
@property (nonatomic, retain) IBOutlet CustomButton *homeButton;
@property (nonatomic, retain) IBOutlet UIView *drawer;
@property (nonatomic, retain) IBOutlet UIButton *drawerCopyButton;
@property (nonatomic, retain) IBOutlet UIButton *drawerPasteButton;

@property (nonatomic, retain) UIView *sideSwipeView;
@property (nonatomic, assign) UITableViewCell *sideSwipeCell;
@property (nonatomic, assign) UISwipeGestureRecognizerDirection sideSwipeDirection;
@property (nonatomic, assign) BOOL animatingSideSwipe;

@end
