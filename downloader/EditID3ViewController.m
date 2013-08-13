//
//  EditID3ViewController.m
//  Swift
//
//  Created by Nathaniel Symer on 8/13/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "EditID3ViewController.h"

@interface EditID3ViewController () <UITextFieldDelegate>

@property (nonatomic, strong) TransparentTextField *artistLabel;
@property (nonatomic, strong) TransparentTextField *titleLabel;
@property (nonatomic, strong) TransparentTextField *albumLabel;

@property (nonatomic, strong) ShadowedNavBar *navBar;

@property (nonatomic, strong) NSMutableDictionary *tag;

@end

@implementation EditID3ViewController

- (void)loadView {
    [super loadView];
    
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];

    self.navBar = [[ShadowedNavBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)];
    _navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:[[kAppDelegate openFile]lastPathComponent]];
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Save" style:UIBarButtonItemStyleBordered target:self action:@selector(writeTags)];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    [_navBar pushNavigationItem:topItem animated:YES];
    [self.view addSubview:_navBar];
    
    self.artistLabel = [[TransparentTextField alloc]initWithFrame:CGRectMake(10, sanitizeMesurement(44), screenBounds.size.width-20, 30)];
    _artistLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _artistLabel.textAlignment = UITextAlignmentCenter;
    _artistLabel.textColor = [UIColor blackColor];
    _artistLabel.font = [UIFont systemFontOfSize:15];
    [self.view addSubview:_artistLabel];
    
    self.titleLabel = [[TransparentTextField alloc]initWithFrame:CGRectMake(10, sanitizeMesurement(44)+40, screenBounds.size.width-20, 30)];
    _titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _titleLabel.textAlignment = UITextAlignmentCenter;
    _titleLabel.textColor = [UIColor blackColor];
    _titleLabel.font = [UIFont systemFontOfSize:15];
    [self.view addSubview:_titleLabel];
    
    self.albumLabel = [[TransparentTextField alloc]initWithFrame:CGRectMake(10, sanitizeMesurement(44)+(40*2), screenBounds.size.width-20, 30)];
    _albumLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _albumLabel.textAlignment = UITextAlignmentCenter;
    _albumLabel.textColor = [UIColor blackColor];
    _albumLabel.font = [UIFont systemFontOfSize:15];
    [self.view addSubview:_albumLabel];
    
    [self loadTags];
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
    
    _artistLabel.text = _tag[@"artist"];
    _titleLabel.text = _tag[@"title"];
    _albumLabel.text = _tag[@"album"];
}

- (void)close {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)writeTags {
    
    NSString *file = [kAppDelegate openFile];
    
    if (![_artistLabel.text isEqualToString:_tag[@"artist"]]) {
        [ID3Editor setArtist:_artistLabel.text forMP3AtPath:file];
        _tag[@"artist"] = _artistLabel.text;
    }
    
    if (![_titleLabel.text isEqualToString:_tag[@"title"]]) {
        [ID3Editor setTitle:_titleLabel.text forMP3AtPath:file];
        _tag[@"title"] = _titleLabel.text;
    }
    
    if (![_albumLabel.text isEqualToString:_tag[@"album"]]) {
        [ID3Editor setAlbum:_albumLabel.text forMP3AtPath:file];
        _tag[@"album"] = _albumLabel.text;
    }
    
    for (NSString *key in _tag.allKeys) {
        NSString *value = _tag[key];
        
        if ([value isEqualToString:@"-"]) {
            value = @"";
        }
        
        _tag[key] = value;
    }
    
    NSString *metadata = [NSString stringWithFormat:@"%@\n%@\n%@",_tag[@"artist"],_tag[@"title"],_tag[@"album"]];
    [AudioPlayerViewController notif_setInfoFieldText:metadata];
    
    [self close];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
