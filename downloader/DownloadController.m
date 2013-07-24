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
CGFloat UIInterfaceOrientationAngleOfOrientation(UIInterfaceOrientation orientation);

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

CGFloat UIInterfaceOrientationAngleOfOrientation(UIInterfaceOrientation orientation) {
    CGFloat angle;
    
    switch (orientation) {
        case UIInterfaceOrientationPortraitUpsideDown:
            angle = M_PI;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            angle = -M_PI/2;
            break;
        case UIInterfaceOrientationLandscapeRight:
            angle = M_PI/2;
            break;
        default:
            angle = 0.0;
            break;
    }
    
    return angle;
}

static NSString * const cellId = @"DownloadCell";

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
    [self updateSizes];
}

- (void)addDownload:(Download *)download {
    [_downloadObjs addObject:download];
    [download start];
    [self updateSizes];
}

- (void)removeDownloadAtIndex:(int)index {
    [self removeDownload:[_downloadObjs objectAtIndex:index]];
}

- (int)tagForDownload:(Download *)download {
    return [_downloadObjs indexOfObject:download];
}

//
// Rotation
//

- (void)registerForNotif {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

- (void)didRotate:(NSNotification *)notification {
    [self layoutSubviews];
}

- (void)layoutSubviews {
    float padding = 5;
    CGSize screenSize = [[[UIApplication sharedApplication]keyWindow]bounds].size;
    float height = (_downloadObjs.count*45)+40;
    
    CGFloat angle = UIInterfaceOrientationAngleOfOrientation([UIApplication sharedApplication].statusBarOrientation);
    CGAffineTransform transform = CGAffineTransformMakeRotation(angle);
    
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        // height and width are switched because UIWindow doesn't rotate its coordinate plane
        self.transform = CGAffineTransformTranslate(transform, -screenSize.height/2, (screenSize.width/2)-(self.bounds.size.height/2));
        _mainView.transform = CGAffineTransformTranslate(transform, -screenSize.height/2, (screenSize.width/2)-(_mainView.bounds.size.height/2));
        _mainView.frame = CGRectMake(padding, padding, height, screenSize.height-(padding*2)); // height and width, x and y are reversed
    } else {
        self.transform = CGAffineTransformIdentity;
        _mainView.transform = CGAffineTransformIdentity;
        _mainView.frame = CGRectMake(padding, screenSize.height-padding-height, screenSize.width-(padding*2), height);
    }
    
    _theTableView.frame = CGRectMake(0, 40, _mainView.frame.size.width, (_downloadObjs.count*45));

    self.frame = CGRectMake(10, screenSize.height-10-42-5, 42+5, 42+5);
    
    _button.frame = self.bounds;
    _activity.frame = self.bounds;
}

//
// UI
//

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
    
    [_theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    
    [UIView animateWithDuration:0.25 animations:^{
        [self layoutSubviews]; // it's legit because I don't call through to super.
    }];
}

- (void)setupTableView {

    if (!_mainView) {
        self.mainView = [[UIView alloc]init];
        _mainView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.6f];
        _mainView.layer.cornerRadius = 5;
        
        UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        backButton.frame = CGRectMake(5, 5, 50, 30);
        backButton.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.8f];
        backButton.layer.cornerRadius = 5;
        [backButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [backButton setBackgroundImage:imageWithColorAndSize([UIColor colorWithWhite:0.5f alpha:0.6f], backButton.frame.size) forState:UIControlStateHighlighted];
        [backButton setTitle:@"Close" forState:UIControlStateNormal];
        [backButton addTarget:self action:@selector(strikedownTableView) forControlEvents:UIControlEventTouchUpInside];
        [_mainView addSubview:backButton];
        
        UILabel *dl = [[UILabel alloc]initWithFrame:CGRectMake(100, 5, _mainView.bounds.size.width-180, 30)];
        dl.text = @"Downloads";
        dl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        dl.font = [UIFont boldSystemFontOfSize:20];
        dl.backgroundColor = [UIColor clearColor];
        dl.textColor = [UIColor whiteColor];
        dl.textAlignment = UITextAlignmentCenter;
        [_mainView addSubview:dl];
        
        self.theTableView = [[UITableView alloc]init];
        _theTableView.dataSource = self;
        _theTableView.delegate = self;
        _theTableView.allowsSelection = NO;
        _theTableView.backgroundColor = [UIColor clearColor];
        _theTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [_mainView addSubview:_theTableView];
    }
}

- (void)strikedownTableView {
    [UIView animateWithDuration:0.25 animations:^{
        [_mainView removeFromSuperview];
        [self setHidden:NO];
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
    cell.customTitleLabel.text = [download.fileName percentSanitize];
    return cell;
}

//
// Layover button
//

- (void)showTableViewer {
    [UIView animateWithDuration:0.25 animations:^{
        [self setHidden:YES];
        [[kAppDelegate window]addSubview:_mainView];
    }];
}

- (void)show {
    [[kAppDelegate window]addSubview:self];
    self.hidden = YES;
    [UIView animateWithDuration:0.25 animations:^{
        self.hidden = NO;
    }];
}

- (void)hide {
    [UIView animateWithDuration:0.25 animations:^{
        self.hidden = YES;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        self.hidden = NO;
    }];
}

- (id)init {
    self = [super init];
    if (self) {
        [self registerForNotif];
        self.activity = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        self.button = [UIButton buttonWithType:UIButtonTypeCustom];
        
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
        self.layer.cornerRadius = 7.5;
        
        [_button addTarget:self action:@selector(showTableViewer) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_activity];
        [self addSubview:_button];
        [_activity startAnimating];
        
        self.downloadObjs = [NSMutableArray array];
        
        [self setupTableView];
    }
    return self;
}

+ (DownloadController *)sharedController {
    static DownloadController *sharedController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedController = [[DownloadController alloc]init];
    });
    
    return sharedController;
}

@end
