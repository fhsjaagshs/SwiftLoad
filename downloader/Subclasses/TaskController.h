//
//  TaskController.h
//  Swift
//
//  Created by Nathaniel Symer on 7/28/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TaskController : UIView

- (void)hide;
- (void)show;

- (void)removeAllTasks;
- (void)removeTask:(Task *)download;
- (void)addTask:(Task *)download;

- (void)removeTaskAtIndex:(int)index;

- (int)indexOfTask:(Task *)download;

+ (TaskController *)sharedController;

@end
