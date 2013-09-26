//
//  EditID3ViewController.m
//  Swift
//
//  Created by Nathaniel Symer on 8/13/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "EditID3ViewController.h"

static NSString * const kID3EditorCellID = @"kID3EditorCellID";

@interface EditID3ViewController () <UITextFieldDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITextField *artistField;
@property (nonatomic, strong) UITextField *titleField;
@property (nonatomic, strong) UITextField *albumField;

@property (nonatomic, strong) NSMutableDictionary *tag;

@property (nonatomic, assign) BOOL hasGuidedUserToEdit;

@end

@implementation EditID3ViewController

- (void)loadView {
    [super loadView];
    
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    
    UITableView *theTableView = [[UITableView alloc]initWithFrame:screenBounds style:UITableViewStyleGrouped];
    theTableView.dataSource = self;
    theTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    theTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    theTableView.rowHeight = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)?60:44;
    theTableView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
    theTableView.scrollIndicatorInsets = theTableView.contentInset;
    [self.view addSubview:theTableView];
    
    UINavigationBar *navBar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 64)];
    navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"Edit Metadata"];
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Save" style:UIBarButtonItemStyleBordered target:self action:@selector(writeTags)];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    [navBar pushNavigationItem:topItem animated:YES];
    [self.view addSubview:navBar];
    
    self.artistField = [[UITextField alloc]init];
    _artistField.returnKeyType = UIReturnKeyDone;
    _artistField.placeholder = @"Artist";
    _artistField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _artistField.textColor = [UIColor blackColor];
    _artistField.font = [UIFont fontWithName:@"Avenir-Medium" size:17];
    _artistField.borderStyle = UITextBorderStyleNone;
    _artistField.keyboardAppearance = UIKeyboardAppearanceAlert;
    _artistField.backgroundColor = [UIColor whiteColor];
    _artistField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _artistField.autocorrectionType = UITextAutocorrectionTypeNo;
    _artistField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _artistField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _artistField.leftViewMode = UITextFieldViewModeAlways;
    _artistField.leftView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 10, 10)];
    
    self.titleField = [[UITextField alloc]init];
    _titleField.returnKeyType = UIReturnKeyDone;
    _titleField.placeholder = @"Title";
    _titleField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _titleField.textColor = [UIColor blackColor];
    _titleField.font = [UIFont fontWithName:@"Avenir-Medium" size:17];
    _titleField.borderStyle = UITextBorderStyleNone;
    _titleField.keyboardAppearance = UIKeyboardAppearanceAlert;
    _titleField.backgroundColor = [UIColor whiteColor];
    _titleField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _titleField.autocorrectionType = UITextAutocorrectionTypeNo;
    _titleField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _titleField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _titleField.leftViewMode = UITextFieldViewModeAlways;
    _titleField.leftView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 10, 10)];
    
    self.albumField = [[UITextField alloc]init];
    _albumField.returnKeyType = UIReturnKeyDone;
    _albumField.placeholder = @"Album";
    _albumField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _albumField.textColor = [UIColor blackColor];
    _albumField.font = [UIFont fontWithName:@"Avenir-Medium" size:17];
    _albumField.borderStyle = UITextBorderStyleNone;
    _albumField.keyboardAppearance = UIKeyboardAppearanceAlert;
    _albumField.backgroundColor = [UIColor whiteColor];
    _albumField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _albumField.autocorrectionType = UITextAutocorrectionTypeNo;
    _albumField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _albumField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _albumField.leftViewMode = UITextFieldViewModeAlways;
    _albumField.leftView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 10, 10)];
    
    [_artistField addTarget:_artistField action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
    [_titleField addTarget:_titleField action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
    [_albumField addTarget:_albumField action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
    
    [self loadTags];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!_hasGuidedUserToEdit) {
        [_artistField becomeFirstResponder];
        self.hasGuidedUserToEdit = YES;
    }
}

- (void)loadTags {
    
    self.tag = [NSMutableDictionary dictionary];
    
    NSDictionary *id3 = [ID3Editor loadTagFromFile:[kAppDelegate openFile]];
    
    for (NSString *key in id3.allKeys) {
        NSString *value = id3[key];
        
        if ([value isEqualToString:@"-"]) {
            value = @"";
        }
        
        _tag[key] = value;
    }
    
    _artistField.text = _tag[@"artist"];
    _titleField.text = _tag[@"title"];
    _albumField.text = _tag[@"album"];
}

- (void)close {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)writeTags {
    
    NSString *file = [kAppDelegate openFile];
    
    if (![_artistField.text isEqualToString:_tag[@"artist"]]) {
        [ID3Editor setArtist:_artistField.text forMP3AtPath:file];
        _tag[@"artist"] = _artistField.text;
    }
    
    if (![_titleField.text isEqualToString:_tag[@"title"]]) {
        [ID3Editor setTitle:_titleField.text forMP3AtPath:file];
        _tag[@"title"] = _titleField.text;
    }
    
    if (![_albumField.text isEqualToString:_tag[@"album"]]) {
        [ID3Editor setAlbum:_albumField.text forMP3AtPath:file];
        _tag[@"album"] = _albumField.text;
    }
    
    for (NSString *key in _tag.allKeys) {
        NSString *value = _tag[key];
        
        if ([value isEqualToString:@""]) {
            value = @"-";
        }
        
        _tag[key] = value;
    }
    
    NSString *metadata = [NSString stringWithFormat:@"%@\n%@\n%@",_tag[@"artist"],_tag[@"title"],_tag[@"album"]];
    [AudioPlayerViewController notif_setInfoFieldText:metadata];
    
    [self close];
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
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kID3EditorCellID];
    
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kID3EditorCellID];
    }
    
    [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    if (indexPath.row == 0) {
        [cell.contentView addSubview:_artistField];
        _artistField.frame = cell.bounds;
    } else if (indexPath.row == 1) {
        [cell.contentView addSubview:_titleField];
        _titleField.frame = cell.bounds;
    } else if (indexPath.row == 2) {
        [cell.contentView addSubview:_albumField];
        _albumField.frame = cell.bounds;
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
