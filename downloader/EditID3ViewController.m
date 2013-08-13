//
//  EditID3ViewController.m
//  Swift
//
//  Created by Nathaniel Symer on 8/13/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "EditID3ViewController.h"

@interface EditID3ViewController ()

@property (nonatomic, strong) TransparentTextField *artistLabel;
@property (nonatomic, strong) TransparentTextField *titleLabel;
@property (nonatomic, strong) TransparentTextField *albumLabel;

@property (nonatomic, strong) ShadowedNavBar *navBar;

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
    
    self.artistLabel = [[TransparentTextField alloc]initWithFrame:CGRectMake(0, sanitizeMesurement(44), screenBounds.size.width, 20)];
    _artistLabel.textAlignment = UITextAlignmentCenter;
    _artistLabel.backgroundColor = [UIColor clearColor];
    _artistLabel.textColor = [UIColor blackColor];
    _artistLabel.font = [UIFont systemFontOfSize:15];
    [self.view addSubview:_artistLabel];
    
    self.titleLabel = [[TransparentTextField alloc]initWithFrame:CGRectMake(0, sanitizeMesurement(44)+20, screenBounds.size.width, 20)];
    _titleLabel.textAlignment = UITextAlignmentCenter;
    _titleLabel.backgroundColor = [UIColor clearColor];
    _titleLabel.textColor = [UIColor blackColor];
    _titleLabel.font = [UIFont systemFontOfSize:15];
    _titleLabel.opaque = NO;
    _titleLabel.enabled = YES;
    [self.view addSubview:_titleLabel];
    
    self.albumLabel = [[TransparentTextField alloc]initWithFrame:CGRectMake(0, sanitizeMesurement(44)+(20*2), screenBounds.size.width, 20)];
    _albumLabel.textAlignment = UITextAlignmentCenter;
    _albumLabel.backgroundColor = [UIColor clearColor];
    _albumLabel.textColor = [UIColor blackColor];
    _albumLabel.font = [UIFont systemFontOfSize:15];
    [self.view addSubview:_albumLabel];
    
    [self loadTags];
}

- (void)loadTags {
    NSDictionary *id3 = [ID3Editor loadTagFromFile:[kAppDelegate openFile]];
    
    _artistLabel.text = id3[@"artist"];
    _titleLabel.text = id3[@"title"];
    _albumLabel.text = id3[@"album"];
}

- (void)close {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)writeTags {
    
    NSString *file = [kAppDelegate openFile];
    
    NSDictionary *id3 = [ID3Editor loadTagFromFile:file];
    
    if (![_artistLabel.text isEqualToString:id3[@"artist"]]) {
        [ID3Editor setArtist:_artistLabel.text forMP3AtPath:file];
    }
    
    if (![_titleLabel.text isEqualToString:id3[@"title"]]) {
        [ID3Editor setTitle:_titleLabel.text forMP3AtPath:file];
    }
    
    if (![_albumLabel.text isEqualToString:id3[@"album"]]) {
        [ID3Editor setAlbum:_albumLabel.text forMP3AtPath:file];
    }
    [self close];
}

@end
