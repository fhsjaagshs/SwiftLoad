//
//  DownloadController.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/18/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "DownloadController.h"
#import "DownloadingCell.h"

UIImage * imageWithColorAndSize(UIColor *color, CGSize size);

UIImage * imageWithColorAndSize(UIColor *color, CGSize size) {
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context,color.CGColor);
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, size.width, size.height) cornerRadius:7];
    
    CGContextAddPath(context, path.CGPath);
    CGContextFillPath(context);
    
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

static DownloadController *sharedInstance = nil;

static NSString * const cellId = @"acellid";

@interface DownloadController ()  <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, retain) UIButton *button;
@property (nonatomic, retain) UIActivityIndicatorView *activity;

@property (nonatomic, retain) UITableView *theTableView;
@property (nonatomic, retain) UIView *mainView;

@end

@implementation DownloadController

//
// Notification
//

- (void)notifReceived:(NSNotification *)notif {
    [_theTableView reloadData];
    [self updateButtonNumber:[[Downloads sharedDownloads]numberDownloads]];
    [self updateSizes];
}

//
// TableView
//

- (void)updateSizes {
    [UIView animateWithDuration:0.25 animations:^{
        float height = ([[Downloads sharedDownloads]numberDownloads]*45)+40;
        _mainView.frame = CGRectMake(_mainView.frame.origin.x, [[UIScreen mainScreen]bounds].size.height-5-height, _mainView.frame.size.width, height);
        _theTableView.frame = CGRectMake(0, 40, _mainView.frame.size.width, ([[Downloads sharedDownloads]numberDownloads]*45));
    }];
}

- (void)setupTableView {

    if (!_mainView) {
        CGSize screenSize = [[UIScreen mainScreen]bounds].size;
        float padding = 5;
        
        float height = ([[Downloads sharedDownloads]numberDownloads]*45)+40;
        
        self.mainView = [[[UIView alloc]initWithFrame:CGRectMake(padding, screenSize.height-5-height, screenSize.width-(padding*2), height)]autorelease];
        _mainView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.6f];
        _mainView.layer.cornerRadius = 10;
        
        UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        backButton.frame = CGRectMake(5, 5, 50, 30);
        backButton.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.8f];
        backButton.layer.cornerRadius = 7;
        [backButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [backButton setBackgroundImage:imageWithColorAndSize([UIColor colorWithWhite:0.5f alpha:0.6f], backButton.frame.size) forState:UIControlStateHighlighted];
        [backButton setTitle:@"Close" forState:UIControlStateNormal];
        [backButton addTarget:self action:@selector(strikedownTableView) forControlEvents:UIControlEventTouchUpInside];
        [_mainView addSubview:backButton];
        
        UILabel *dl = [[[UILabel alloc]initWithFrame:CGRectMake(100, 5, _mainView.bounds.size.width-180, 30)]autorelease];
        dl.text = @"Downloads";
        dl.font = [UIFont boldSystemFontOfSize:20];
        dl.backgroundColor = [UIColor clearColor];
        dl.textColor = [UIColor whiteColor];
        dl.textAlignment = UITextAlignmentCenter;
        [_mainView addSubview:dl];
        
        self.theTableView = [[[UITableView alloc]initWithFrame:CGRectMake(0, 40, _mainView.bounds.size.width, ([[Downloads sharedDownloads]numberDownloads]*45))]autorelease];
        _theTableView.dataSource = self;
        _theTableView.delegate = self;
        _theTableView.allowsSelection = NO;
        _theTableView.backgroundColor = [UIColor clearColor];
        _theTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [_mainView addSubview:_theTableView];
    }
    
    [[((downloaderAppDelegate *)[[UIApplication sharedApplication]delegate])window]addSubview:_mainView];
}

- (void)strikedownTableView {
    [UIView animateWithDuration:0.25 animations:^{
        [_mainView removeFromSuperview];
        [self setHidden:NO];
        if ([[Downloads sharedDownloads]numberDownloads] == 0) {
            [_theTableView removeFromSuperview];
            [self setMainView:nil];
            [self setTheTableView:nil];
        }
    }];
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
        [_theTableView beginUpdates];
        [_theTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
        [[Downloads sharedDownloads]removeDownloadAtIndex:indexPath.row];
        [_theTableView endUpdates];
        [self updateSizes];
        [self updateButtonNumber:[[Downloads sharedDownloads]numberDownloads]];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DownloadingCell *cell = (DownloadingCell *)[_theTableView dequeueReusableCellWithIdentifier:cellId];
    
    if (!cell) {
        cell = [[[DownloadingCell alloc]initWithReuseIdentifier:cellId]autorelease];
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
    [UIView animateWithDuration:0.25 animations:^{
        [self setHidden:YES];
        [self setupTableView];
    }];
}

- (void)show {
    [UIView animateWithDuration:0.25 animations:^{
        [[((downloaderAppDelegate *)[[UIApplication sharedApplication]delegate])window]addSubview:self];
    }];
}

- (void)hide {
    [UIView animateWithDuration:0.25 animations:^{
        [self removeFromSuperview];
    }];
}

- (void)updateButtonNumber:(int)number {
    if (number < 1) {
        [_button setTitle:@"0" forState:UIControlStateNormal];
        if (self.superview) {
            [self hide];
        }
    } else {
        if (!self.superview) {
            [self show];
        }
        
        [_button setTitle:[NSString stringWithFormat:@"%d",number] forState:UIControlStateNormal];
    }
}

- (id)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(notifReceived:) name:kDownloadChanged object:nil];
        
        self.activity = [[[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge]autorelease];
        self.button = [UIButton buttonWithType:UIButtonTypeCustom];
        
        float awidth = _activity.frame.size.width;
        float aheight = _activity.frame.size.height;
        
        CGSize screenSize = [[UIScreen mainScreen]bounds].size;
        float padding = 10;
        
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
        self.frame = CGRectMake(padding, screenSize.height-padding-aheight-5, awidth+5, aheight+5);
        self.layer.cornerRadius = 7.5;
        
        _button.frame = self.bounds;
        _activity.frame = self.bounds;
        
        [_button addTarget:self action:@selector(showTableViewer) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_activity];
        [self addSubview:_button];
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
    [self setButton:nil];
    [self setActivity:nil];
    [self setTheTableView:nil];
    [self setMainView:nil];
    [super dealloc];
}

@end
