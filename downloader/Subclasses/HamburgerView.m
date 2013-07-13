//
//  HamburgerView.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 7/13/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "HamburgerView.h"
#import "HamburgerCell.h"

@interface HamburgerView () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, retain) UITableView *theTableView;

@end

@implementation HamburgerView

+ (HamburgerView *)view {
    return [[[[self class]alloc]init]autorelease];
}

- (id)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.frame = CGRectMake(0, 0, 270, [[UIScreen mainScreen]applicationFrame].size.height);
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
    
    // set title based on index
    
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
    if (_delegate && [_delegate respondsToSelector:@selector(hamburgerWasSelectedAtIndex)]) {
        [_delegate hamburgerCellWasSelectedAtIndex:indexPath.row];
    }
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
    BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    
    self.theTableView = [[[CoolRefreshTableView alloc]initWithFrame:self.bounds style:UITableViewStylePlain]autorelease];
    _theTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _theTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _theTableView.backgroundColor = [UIColor clearColor];
    _theTableView.rowHeight = iPad?60:44;
    _theTableView.dataSource = self;
    _theTableView.delegate = self;
    _theTableView.allowsSelectionDuringEditing = YES;
    _theTableView.canCancelContentTouches = NO;
    [self addSubview:_theTableView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _theTableView.frame = self.bounds;
}

@end
