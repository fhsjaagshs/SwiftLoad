//
//  Hamburger.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 7/13/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "Hamburger.h"
#import "HamburgerCell.h"

@interface HamburgerView : UIView <UITableViewDataSource, UITableViewDelegate>

+ (HamburgerView *)view;

@property (nonatomic, assign) id<HamburdgerViewDelegate> delegate;
@property (nonatomic, retain) UITableView *theTableView;
@property (nonatomic, assign) HamburgerButtonItem *item;

@end

@interface HamburgerButtonItem ()

@property (nonatomic, strong) HamburgerView *hamburgerView;
@property (nonatomic, strong) UIButton *hideButton;
@property (nonatomic, assign) UIView *viewToMove;

@end

@implementation HamburgerButtonItem

+ (HamburgerButtonItem *)itemWithView:(UIView *)viewToMove {
    HamburgerButtonItem *item = [[[HamburgerButtonItem alloc]initWithTitle:@"Ham" style:UIBarButtonItemStyleBordered target:nil action:nil]autorelease];
    [item setTarget:item];
    [item setAction:@selector(toggleState)];
    item.hamburgerView = [HamburgerView view];
    item.hamburgerView.item = item;
    item.viewToMove = viewToMove;
    item.hideButton = [UIButton buttonWithType:UIButtonTypeCustom];
    item.hideButton.frame = item.viewToMove.bounds;
    [item.hideButton addTarget:item action:@selector(hide) forControlEvents:UIControlEventTouchDown];
    return item;
}

- (void)setDelegate:(id<HamburdgerViewDelegate>)delegate {
    [_hamburgerView setDelegate:delegate];
}

- (void)hide {
    [UIView animateWithDuration:0.3f animations:^{
        _viewToMove.frame = CGRectMake(0, _viewToMove.frame.origin.y, _viewToMove.frame.size.width, _viewToMove.frame.size.height);
    } completion:^(BOOL finished) {
        [_hamburgerView removeFromSuperview];
        [_hideButton removeFromSuperview];
    }];
}

- (void)show {
    [[kAppDelegate window]insertSubview:_hamburgerView belowSubview:_viewToMove];
    [_viewToMove addSubview:_hideButton];
    [UIView animateWithDuration:0.3f animations:^{
        _hamburgerView.frame = CGRectMake(0, 20, 250, [[UIScreen mainScreen]applicationFrame].size.height);
        _viewToMove.frame = CGRectMake(250, _viewToMove.frame.origin.y, _viewToMove.frame.size.width, _viewToMove.frame.size.height);
        
    }];
}

- (void)toggleState {
    if (_hamburgerView.superview) {
        [self hide];
    } else {
        [self show];
    }
}

@end

@implementation HamburgerView

+ (HamburgerView *)view {
    return [[[[self class]alloc]init]autorelease];
}

- (id)init {
    self = [super init];
    if (self) {
        self.userInteractionEnabled = YES;
        self.backgroundColor = [UIColor clearColor];
        self.frame = CGRectMake(0, 0, 250, [[UIScreen mainScreen]applicationFrame].size.height);
        [self setup];
    }
    return self;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 5;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    HamburgerCell *cell = [HamburgerCell dequeueReusableCellFromTableView:tableView];
    
    if (cell == nil) {
        cell = [HamburgerCell cell];
    }
    
    int row = indexPath.row;
    
    if (row == 0) {
        cell.textLabel.text = @"Download URL";
    } else if (row == 1) {
        cell.textLabel.text = @"WebDAV Server";
    } else if (row == 2) {
        cell.textLabel.text = @"Browse Dropbox";
    } else if (row == 3) {
        cell.textLabel.text = @"Browse SFTP";
    } else if (row == 4) {
        cell.textLabel.text = @"Settings";
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_delegate && [_delegate respondsToSelector:@selector(hamburgerCellWasSelectedAtIndex:)]) {
        [_item hide];
        [_delegate hamburgerCellWasSelectedAtIndex:indexPath.row];
    }
    [_theTableView deselectRowAtIndexPath:indexPath animated:YES];
}

/*- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
 // maybe, depends on how viewForHeaderInSection: works
 }
 
 - (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
 // say main menu
 }
 
 - (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
 // version label
 }*/

- (void)setup {
    self.theTableView = [[[UITableView alloc]initWithFrame:self.bounds style:UITableViewStylePlain]autorelease];
    _theTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _theTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _theTableView.backgroundColor = [UIColor clearColor];
    _theTableView.rowHeight = 44;
    _theTableView.dataSource = self;
    _theTableView.delegate = self;
    [self addSubview:_theTableView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _theTableView.frame = self.bounds;
}

@end

