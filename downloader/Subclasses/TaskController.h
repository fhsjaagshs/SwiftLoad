//
//  TaskController.h
//  Swift
//
//  Created by Nathaniel Symer on 7/28/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TaskController : UIView

- (void)removeAllTasks;
- (void)removeTask:(Task *)download;
- (void)addTask:(Task *)download;

- (Task *)taskAtIndex:(int)index;

- (void)removeTaskAtIndex:(int)index;

- (int)indexOfTask:(Task *)download;

- (int)numberOfTasks;

+ (TaskController *)sharedController;

@end
