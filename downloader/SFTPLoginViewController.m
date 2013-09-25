//
//  SFTPLoginViewController.m
//  Swift
//
//  Created by Nathaniel Symer on 9/23/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "SFTPLoginViewController.h"

static NSString * const kSFTPLoginCellID = @"kSFTPLoginCellID";

@interface SFTPLoginViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) UITableView *theTableView;
@property (nonatomic, strong) UITextField *serverField;
@property (nonatomic, strong) UITextField *usernameField;
@property (nonatomic, strong) UITextField *passwordField;

@end

@implementation SFTPLoginViewController

- (void)loadView {
    [super loadView];
    CGRect screenBounds = [[UIScreen mainScreen]bounds];
    
    self.serverField = [[UITextField alloc]init];
    _serverField.keyboardAppearance = UIKeyboardAppearanceAlert;
    _serverField.borderStyle = UITextBorderStyleNone;
    _serverField.backgroundColor = [UIColor whiteColor];
    _serverField.returnKeyType = UIReturnKeyNext;
    _serverField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _serverField.autocorrectionType = UITextAutocorrectionTypeNo;
    _serverField.placeholder = @"sftp://example.com/home/me/";
    _serverField.font = [UIFont systemFontOfSize:18];
    _serverField.adjustsFontSizeToFitWidth = YES;
    _serverField.delegate = self;
    _serverField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _serverField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _serverField.leftViewMode = UITextFieldViewModeAlways;
    _serverField.leftView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 10, 10)];
    
    self.usernameField = [[UITextField alloc]init];
    _usernameField.keyboardAppearance = UIKeyboardAppearanceAlert;
    _usernameField.borderStyle = UITextBorderStyleNone;
    _usernameField.backgroundColor = [UIColor whiteColor];
    _usernameField.returnKeyType = UIReturnKeyNext;
    _usernameField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _usernameField.autocorrectionType = UITextAutocorrectionTypeNo;
    _usernameField.placeholder = @"Username";
    _usernameField.font = [UIFont systemFontOfSize:18];
    _usernameField.adjustsFontSizeToFitWidth = YES;
    _usernameField.delegate = self;
    _usernameField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _usernameField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _usernameField.leftViewMode = UITextFieldViewModeAlways;
    _usernameField.leftView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 10, 10)];
    
    self.passwordField = [[UITextField alloc]init];
    _passwordField.keyboardAppearance = UIKeyboardAppearanceAlert;
    _passwordField.borderStyle = UITextBorderStyleNone;
    _passwordField.backgroundColor = [UIColor whiteColor];
    _passwordField.returnKeyType = UIReturnKeyDone;
    _passwordField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _passwordField.autocapitalizationType = UITextAutocorrectionTypeNo;
    _passwordField.placeholder = @"Password";
    _passwordField.font = [UIFont systemFontOfSize:18];
    _passwordField.adjustsFontSizeToFitWidth = YES;
    _passwordField.secureTextEntry = YES;
    _passwordField.delegate = self;
    _passwordField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _passwordField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _passwordField.leftViewMode = UITextFieldViewModeAlways;
    _passwordField.leftView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 10, 10)];
    
    self.theTableView = [[UITableView alloc]initWithFrame:screenBounds style:UITableViewStyleGrouped];
    _theTableView.delegate = self;
    _theTableView.dataSource = self;
    _theTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    _theTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _theTableView.rowHeight = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)?60:44;
    _theTableView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
    _theTableView.scrollIndicatorInsets = _theTableView.contentInset;
    [self.view addSubview:_theTableView];
    
    UINavigationBar *bar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 64)];
    bar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"SFTP Login"];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(close)];
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Login" style:UIBarButtonItemStylePlain target:self action:@selector(connect)];
    [bar pushNavigationItem:topItem animated:NO];
    [self.view addSubview:bar];
    
    [_serverField addTarget:self action:@selector(moveOnServerField) forControlEvents:UIControlEventEditingDidEndOnExit];
    [_usernameField addTarget:self action:@selector(moveOnUsernameField) forControlEvents:UIControlEventEditingDidEndOnExit];
    [_passwordField addTarget:self action:@selector(connect) forControlEvents:UIControlEventEditingDidEndOnExit];
}

- (void)connect {
    [self dismissViewControllerAnimated:YES completion:^{
        if (_loginBlock) {
            _loginBlock(_serverField.text, _usernameField.text, _passwordField.text);
        }
    }];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kSFTPLoginCellID];
    
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kSFTPLoginCellID];
    }
    
    [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    if (indexPath.row == 0) {
        [cell.contentView addSubview:_serverField];
        _serverField.frame = cell.bounds;
    } else if (indexPath.row == 1) {
        [cell.contentView addSubview:_usernameField];
        _usernameField.frame = cell.bounds;
    } else if (indexPath.row == 2) {
        [cell.contentView addSubview:_passwordField];
        _passwordField.frame = cell.bounds;
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (void)moveOnServerField {
    if ([_serverField isFirstResponder]) {
        [_serverField resignFirstResponder];
    }
    [_usernameField becomeFirstResponder];
}

- (void)moveOnUsernameField {
    if ([_usernameField isFirstResponder]) {
        [_usernameField resignFirstResponder];
    }
    [_passwordField becomeFirstResponder];
}

- (void)close {
    [self dismissViewControllerAnimated:YES completion:^{
        if (_cancellationBlock) {
            _cancellationBlock();
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [_theTableView reloadData];
}

- (void)dropboxAuthenticationFailed {
    [_theTableView reloadData];
}

- (void)dropboxAuthenticationSucceeded {
    [_theTableView reloadData];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end
