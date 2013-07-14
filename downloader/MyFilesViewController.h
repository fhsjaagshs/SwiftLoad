//
//  MyFilesViewController.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 8/11/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShadowedTableView.h"
#import "ShadowedNavBar.h"
#import "CoolRefreshTableView.h"

@interface MyFilesViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIDocumentInteractionControllerDelegate, ContentOffsetWatchdogDelegate>

// Copy/Cut/Paste
@property (nonatomic, strong) NSMutableArray *copiedList;
@property (nonatomic, strong) NSMutableArray *perspectiveCopiedList;
@property (nonatomic, assign) BOOL isCut;

//@property (nonatomic, retain) UIDocumentInteractionController *docController;

@property (nonatomic, strong) NSMutableArray *filelist;
@property (nonatomic, strong) NSMutableArray *dirs;

@property (nonatomic, strong) UIBarButtonItem *editButton;
@property (nonatomic, strong) CoolRefreshTableView *theTableView;
@property (nonatomic, strong) ShadowedNavBar *navBar;
@property (nonatomic, strong) UIButton *theCopyAndPasteButton;

@property (nonatomic, strong) UIView *sideSwipeView;
@property (nonatomic, weak) UITableViewCell *sideSwipeCell;
@property (nonatomic, assign) UISwipeGestureRecognizerDirection sideSwipeDirection;
@property (nonatomic, assign) BOOL animatingSideSwipe;

- (void)setWatchdogCanGoYES;

@end
