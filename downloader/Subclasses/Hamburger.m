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

@property (nonatomic, weak) id<HamburgerViewDelegate> delegate;
@property (nonatomic, strong) UITableView *theTableView;
@property (nonatomic, weak) HamburgerButtonItem *item;

@end

@interface HamburgerButtonItem ()

@property (nonatomic, strong) HamburgerView *hamburgerView;
@property (nonatomic, strong) UIButton *hideButton;
@property (nonatomic, weak) UIView *viewToMove;
@property (nonatomic, weak) UIColor *originalBackgroundColor;
@property (nonatomic, assign) BOOL originalOpacity;

@end

@implementation HamburgerButtonItem

+ (HamburgerButtonItem *)itemWithView:(UIView *)viewToMove {
    HamburgerButtonItem *item = [[HamburgerButtonItem alloc]initWithImage:[UIImage imageNamed:@"hamburger"] style:UIBarButtonItemStyleBordered target:nil action:nil];
    [item setTarget:item];
    item.action = @selector(toggleState);
    item.hamburgerView = [HamburgerView view];
    item.hamburgerView.item = item;
    item.hamburgerView.alpha = 0.0f;
    item.viewToMove = viewToMove;
    item.viewToMove.layer.shadowPath = [UIBezierPath bezierPathWithRect:item.viewToMove.bounds].CGPath;
    item.viewToMove.layer.shadowColor = [UIColor blackColor].CGColor;
    item.hideButton = [UIButton buttonWithType:UIButtonTypeCustom];
    item.hideButton.frame = item.viewToMove.bounds;
    [item.hideButton addTarget:item action:@selector(hide) forControlEvents:UIControlEventTouchDown];
    return item;
}

- (void)setDelegate:(id<HamburgerViewDelegate>)delegate {
    [_hamburgerView setDelegate:delegate];
}

- (void)showShadow {
    _viewToMove.layer.shadowOffset = CGSizeMake(-3, 0);
}

- (void)clearShadow {
    _viewToMove.layer.shadowOffset = CGSizeZero;
}

- (void)hide {
    [UIView animateWithDuration:0.3f animations:^{
        _viewToMove.layer.shadowOpacity = 0.0f;
        _hamburgerView.alpha = 0.0f;
        _viewToMove.frame = CGRectMake(0, _viewToMove.frame.origin.y, _viewToMove.frame.size.width, _viewToMove.frame.size.height);
    } completion:^(BOOL finished) {
        [_hamburgerView removeFromSuperview];
        [_hideButton removeFromSuperview];
        [_viewToMove setBackgroundColor:_originalBackgroundColor];
        _viewToMove.layer.shadowOffset = CGSizeZero;
        _viewToMove.layer.shouldRasterize = NO;
    }];
}

- (void)show {
    UIWindow *mainWindow = [kAppDelegate window];
    [mainWindow insertSubview:_hamburgerView belowSubview:_viewToMove];
    [_viewToMove addSubview:_hideButton];
    self.originalBackgroundColor = _viewToMove.backgroundColor;
    [_viewToMove setBackgroundColor:mainWindow.backgroundColor];
    _viewToMove.layer.shadowOffset = CGSizeMake(-3, 0);
    _viewToMove.layer.shouldRasterize = YES;
    _viewToMove.layer.rasterizationScale = [UIScreen mainScreen].scale;
    [UIView animateWithDuration:0.3f animations:^{
        _viewToMove.layer.shadowOpacity = 0.25f;
        _hamburgerView.alpha = 1.0f;
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

- (void)dealloc {
    [self setViewToMove:nil];
}

@end

@implementation HamburgerView

+ (HamburgerView *)view {
    return [[[self class]alloc]init];
}

- (id)init {
    self = [super init];
    if (self) {
        self.userInteractionEnabled = YES;
        self.backgroundColor = bgcolor;
        self.frame = CGRectMake(0, 20, 250, [[UIScreen mainScreen]applicationFrame].size.height);
        self.opaque = YES;
        self.theTableView = [[UITableView alloc]initWithFrame:self.bounds style:UITableViewStylePlain];
        _theTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _theTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _theTableView.backgroundColor = bgcolor;
        _theTableView.rowHeight = 44;
        _theTableView.dataSource = self;
        _theTableView.delegate = self;
        _theTableView.opaque = YES;
        [self addSubview:_theTableView];
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
        cell.backgroundColor = self.backgroundColor;
    }
    
    int row = indexPath.row;
    
    cell.isFirstCell = (indexPath.row == 0);
    
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
    
    [cell setNeedsDisplay];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_delegate && [_delegate respondsToSelector:@selector(hamburgerCellWasSelectedAtIndex:)]) {
        [_item hide];
        [_delegate hamburgerCellWasSelectedAtIndex:indexPath.row];
    }
    [_theTableView deselectRowAtIndexPath:indexPath animated:YES];
}

/*- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return [NSString stringWithFormat:@"Version %@",[[NSBundle mainBundle]objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
}*/

/*- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
 // maybe, depends on how viewForHeaderInSection: works
 }
 
 - (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
 // say main menu
 }
 
 - (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
 // version label
 }*/

- (void)layoutSubviews {
    [super layoutSubviews];
    _theTableView.frame = self.bounds;
}

@end

