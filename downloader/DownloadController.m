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

static NSString * const cellId = @"acellid";

@interface DownloadController ()  <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UIButton *button;
@property (nonatomic, strong) UIActivityIndicatorView *activity;

@property (nonatomic, strong) UITableView *theTableView;
@property (nonatomic, strong) UIView *mainView;

@property (nonatomic, strong) NSMutableArray *downloadObjs;

@end

@implementation DownloadController

//
// Download Management
//

- (int)indexOfDownload:(Download *)download {
    return [_downloadObjs indexOfObject:download];
}

- (void)removeAllDownloads {
    for (Download *download in _downloadObjs) {
        [self removeDownload:download];
    }
}

- (void)removeDownload:(Download *)download {
    [download stop];
    [_downloadObjs removeObject:download];
}

- (void)addDownload:(Download *)download {
    [_downloadObjs addObject:download];
    [download start];
}

- (void)removeDownloadAtIndex:(int)index {
    [self removeDownload:[_downloadObjs objectAtIndex:index]];
}

- (int)tagForDownload:(Download *)download {
    return [_downloadObjs indexOfObject:download];
}

- (void)downloadsChanged {
    [_theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    [self updateSizes];
}

- (void)updateSizes {
    
    if (_downloadObjs.count == 0) {
        [_button setTitle:@"0" forState:UIControlStateNormal];
        if (self.superview) {
            [self hide];
        }
    } else {
        if (!self.superview) {
            [self show];
        }
        
        [_button setTitle:[NSString stringWithFormat:@"%d",_downloadObjs.count] forState:UIControlStateNormal];
    }
    
    [UIView animateWithDuration:0.25 animations:^{
        float height = (_downloadObjs.count*45)+40;
        _mainView.frame = CGRectMake(_mainView.frame.origin.x, [[UIScreen mainScreen]bounds].size.height-5-height, _mainView.frame.size.width, height);
        _theTableView.frame = CGRectMake(0, 40, _mainView.frame.size.width, (_downloadObjs.count*45));
    }];
}

- (void)setupTableView {

    if (!_mainView) {
        CGSize screenSize = [[UIScreen mainScreen]bounds].size;
        float padding = 5;
        
        float height = (_downloadObjs.count*45)+40;
        
        self.mainView = [[UIView alloc]initWithFrame:CGRectMake(padding, screenSize.height-5-height, screenSize.width-(padding*2), height)];
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
        
        UILabel *dl = [[UILabel alloc]initWithFrame:CGRectMake(100, 5, _mainView.bounds.size.width-180, 30)];
        dl.text = @"Downloads";
        dl.font = [UIFont boldSystemFontOfSize:20];
        dl.backgroundColor = [UIColor clearColor];
        dl.textColor = [UIColor whiteColor];
        dl.textAlignment = UITextAlignmentCenter;
        [_mainView addSubview:dl];
        
        self.theTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 40, _mainView.bounds.size.width, (_downloadObjs.count*45))];
        _theTableView.dataSource = self;
        _theTableView.delegate = self;
        _theTableView.allowsSelection = NO;
        _theTableView.backgroundColor = [UIColor clearColor];
        _theTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [_mainView addSubview:_theTableView];
    }
    
    [[kAppDelegate window]addSubview:_mainView];
}

- (void)strikedownTableView {
    [UIView animateWithDuration:0.25 animations:^{
        [_mainView removeFromSuperview];
        [self setHidden:NO];
        if (_downloadObjs.count == 0) {
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
    return _downloadObjs.count;
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
        [self removeDownloadAtIndex:indexPath.row];
        [_theTableView endUpdates];
        [self updateSizes];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DownloadingCell *cell = (DownloadingCell *)[_theTableView dequeueReusableCellWithIdentifier:cellId];
    
    if (!cell) {
        cell = [[DownloadingCell alloc]initWithReuseIdentifier:cellId];
    }
    
    Download *download = [_downloadObjs objectAtIndex:indexPath.row];
    download.delegate = cell;
    cell.titleLabel.text = [download.fileName percentSanitize];
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
        [[kAppDelegate window]addSubview:self];
    }];
}

- (void)hide {
    [UIView animateWithDuration:0.25 animations:^{
        [self removeFromSuperview];
    }];
}

- (id)init {
    self = [super init];
    if (self) {
        self.activity = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
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
    static DownloadController *sharedController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedController = [[DownloadController alloc]init];
    });
    
    return sharedController;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end
