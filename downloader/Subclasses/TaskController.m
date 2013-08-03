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

- (int)numberOfTasks {
    return _taskObjs.count;
}

- (Task *)taskAtIndex:(int)index {
    return [_taskObjs objectAtIndex:index];
}

- (int)indexOfTask:(Task *)task {
    return [_taskObjs indexOfObject:task];
}

- (void)removeAllTasks {
    for (Task *task in _taskObjs) {
        [self removeTask:task];
    }
}

- (void)removeTask:(Task *)task {
    
    if (!task.complete) {
        [task stop];
    }
    
    [_taskObjs removeObject:task];
}

- (void)addTask:(Task *)task {
    [_taskObjs addObject:task];
    [task start];
}

- (void)removeTaskAtIndex:(int)index {
    [self removeTask:[_taskObjs objectAtIndex:index]];
}

- (int)tagForTask:(Task *)task {
    return [_taskObjs indexOfObject:task];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.taskObjs = [NSMutableArray array];
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

