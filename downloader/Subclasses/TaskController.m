//
//  TaskController.m
//  Swift
//
//  Created by Nathaniel Symer on 7/28/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "TaskController.h"

static NSString * const cellId = @"TaskCell";

@interface TaskController ()  <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UIButton *button;
@property (nonatomic, strong) UIActivityIndicatorView *activity;

@property (nonatomic, strong) UITableView *theTableView;
@property (nonatomic, strong) UIView *mainView;

@property (nonatomic, strong) NSMutableArray *taskObjs;

@end

@implementation TaskController

//
// Task Management
//

- (int)indexOfTask:(Task *)task {
    return [_taskObjs indexOfObject:task];
}

- (void)removeAllTasks {
    for (Task *task in _taskObjs) {
        [task stop];
        [_taskObjs removeObject:task];
    }
    [self updateSizes];
}

- (void)removeTask:(Task *)task {
    [task stop];
    [_taskObjs removeObject:task];
    [self updateSizes];
}

- (void)addTask:(Task *)task {
    [_taskObjs addObject:task];
    [task start];
    [self updateSizes];
}

- (void)removeTaskAtIndex:(int)index {
    [self removeTask:[_taskObjs objectAtIndex:index]];
}

- (int)tagForTask:(Task *)task {
    return [_taskObjs indexOfObject:task];
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
    float height = (_taskObjs.count*45)+40;
    _mainView.frame = CGRectMake(padding, screenSize.height-padding-height, screenSize.width-(padding*2), height);
    _theTableView.frame = CGRectMake(0, 40, _mainView.frame.size.width, (_taskObjs.count*45));
    self.frame = CGRectMake(10, screenSize.height-10-42-5, 42+5, 42+5);
    _button.frame = self.bounds;
    _activity.frame = self.bounds;
}

//
// UI
//

- (void)updateSizes {
    if (_taskObjs.count == 0) {
        [_button setTitle:@"0" forState:UIControlStateNormal];
        if (self.superview) {
            [self hide];
        }
    } else {
        if (!self.superview) {
            [self show];
        }
        
        [_button setTitle:[NSString stringWithFormat:@"%d",_taskObjs.count] forState:UIControlStateNormal];
    }
    
    [_theTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    
    [UIView animateWithDuration:0.25 animations:^{
        [self setNeedsLayout];
    }];
}

- (void)setupTableView {
    
    if (!_mainView) {
        self.mainView = [[UIView alloc]init];
        _mainView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.6f];
        _mainView.layer.cornerRadius = 5;
        
        UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        backButton.frame = CGRectMake(5, 5, 50, 30);
        backButton.backgroundColor = [UIColor colorWithWhite:1.0f alpha:1.0f];
        backButton.layer.cornerRadius = 5;
        [backButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [backButton setBackgroundImage:[[UIColor colorWithWhite:0.5f alpha:0.6f]imageWithSize:backButton.frame.size] forState:UIControlStateHighlighted];
        [backButton setTitle:@"Close" forState:UIControlStateNormal];
        [backButton addTarget:self action:@selector(strikedownTableView) forControlEvents:UIControlEventTouchUpInside];
        [_mainView addSubview:backButton];
        
        UILabel *dl = [[UILabel alloc]initWithFrame:CGRectMake(100, 5, _mainView.bounds.size.width-180, 30)];
        dl.text = @"Tasks";
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
    return _taskObjs.count;
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
        [self removeTaskAtIndex:indexPath.row];
        [_theTableView endUpdates];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TaskCell *cell = (TaskCell *)[_theTableView dequeueReusableCellWithIdentifier:cellId];
    
    if (!cell) {
        cell = [[TaskCell alloc]initWithReuseIdentifier:cellId];
    }
    
    Task *task = [_taskObjs objectAtIndex:indexPath.row];
    task.delegate = cell;
    cell.customTitleLabel.text = [task.name percentSanitize];
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
        [self registerForNotif];
        self.activity = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        self.button = [UIButton buttonWithType:UIButtonTypeCustom];
        
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
        self.layer.cornerRadius = 7.5;
        
        [_button addTarget:self action:@selector(showTableViewer) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_activity];
        [self addSubview:_button];
        [_activity startAnimating];
        
        self.taskObjs = [NSMutableArray array];
        
        [self setupTableView];
        [self setNeedsLayout];
    }
    return self;
}

+ (TaskController *)sharedController {
    static TaskController *sharedController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedController = [[TaskController alloc]init];
    });
    return sharedController;
}

@end

