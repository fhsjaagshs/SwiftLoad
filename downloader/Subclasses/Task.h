//
//  Task.h
//  Swift
//
//  Created by Nathaniel Symer on 7/28/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TaskDelegate;

@interface Task : NSObject

@property (nonatomic, assign) BOOL complete;
@property (nonatomic, assign) BOOL succeeded;
@property (nonatomic, strong) NSString *name;

@property (nonatomic, weak) id<TaskDelegate> delegate;

- (void)stop;
- (void)start;

- (BOOL)canStop;

- (void)showSuccess;
- (void)showFailure;

- (void)handleBackgroundTaskExpiration;

- (void)startBackgroundTask;
- (void)cancelBackgroundTask;

- (NSString *)verb;
- (BOOL)canSelect;

@end

@protocol TaskDelegate <NSObject>

- (void)reset;
- (void)drawGreen;
- (void)drawRed;

- (void)setProgress:(float)progress;

- (void)setText:(NSString *)string;
- (void)setDetailText:(NSString *)string;

@end