//
//  DownloadController.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/18/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "DownloadController.h"
#import "DownloadingCell.h"

static DownloadController *sharedInstance = nil;

static NSString * const cellId = @"acellid";

@interface DownloadController ()  <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, retain) UIButton *button;
@property (nonatomic, retain) UIActivityIndicatorView *activity;

@property (nonatomic, retain) UITableView *theTableView;

@end

@implementation DownloadController

//
// Notification
//

- (void)notifReceived:(NSNotification *)notif {
    [_theTableView reloadData];
    [self updateButtonNumber:[[Downloads sharedDownloads]numberDownloads]];
}

//
// TableView
//

- (void)setupTableView {
    self.theTableView = [[UITableView alloc]initWithFrame:self.bounds];
    _theTableView.dataSource = self;
    _theTableView.delegate = self;
}

- (void)strikedownTableView {
    self.theTableView = nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[Downloads sharedDownloads]numberDownloads];
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Cancel";
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [[Downloads sharedDownloads]removeDownloadAtIndex:indexPath.row];
        [_theTableView beginUpdates];
        [_theTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
        [_theTableView endUpdates];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DownloadingCell *cell = (DownloadingCell *)[_theTableView dequeueReusableCellWithIdentifier:cellId];
    
    if (!cell) {
        cell = [[[DownloadingCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId]autorelease];
    }
    
    Download *download = [[Downloads sharedDownloads]downloadAtIndex:indexPath.row];
    download.delegate = cell;
    cell.titleLabel.text = [[download.url lastPathComponent]stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    return cell;
}

//
// Layover button
//

- (void)showTableViewer {
    [self setHidden:YES];
    
    [self setupTableView];
    
}

- (void)tableBrowserWasHidden {
    [self setHidden:NO];
}

- (void)show {
    [[((downloaderAppDelegate *)[[UIApplication sharedApplication]delegate])window]addSubview:self];
}

- (void)hide {
    [self removeFromSuperview];
}

- (void)updateButtonNumber:(int)number {
    if (number < 1) {
        [_button setHidden:YES];
        [_button setTitle:@"0" forState:UIControlStateNormal];
    } else {
        [_button setTitle:[NSString stringWithFormat:@"%d",number] forState:UIControlStateNormal];
        [_button setHidden:NO];
    }
}

- (id)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(notifReceived:) name:kDownloadChanged object:nil];
        self.activity = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        self.button = [UIButton buttonWithType:UIButtonTypeCustom];
        float awidth = _activity.frame.size.width;
        float aheight = _activity.frame.size.height;
        CGSize screenSize = [[UIScreen mainScreen]applicationFrame].size;
        float padding = 10;
        self.frame = CGRectMake(awidth+padding, screenSize.height-aheight-padding, awidth+5, aheight+5);
        UIColor *bgcolor = [UIColor colorWithWhite:0 alpha:0.6];
        [_button setBackgroundColor:bgcolor];
        [_button addTarget:self action:@selector(showTableViewer) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_button];
        [self addSubview:_activity];
        [_activity startAnimating];
    }
    return self;
}

//
// Singleton crap
//

+ (DownloadController *)sharedController {
    @synchronized (self) {
        if (sharedInstance == nil) {
            [[self alloc]init];
        }
    }
    return sharedInstance;
}

// Override stuff to make sure that the singleton is never dealloc'd. Fun.
+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedInstance == nil) {
            sharedInstance = [super allocWithZone:zone];
            return sharedInstance;
        }
    }
    return nil;
}

- (id)retain {
    return self;
}

- (oneway void)release {
    // Do nothing
}

- (id)autorelease {
    return self;
}

- (NSUInteger)retainCount {
    return NSUIntegerMax;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [super dealloc];
}

@end
