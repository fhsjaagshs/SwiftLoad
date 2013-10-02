//
//  P2PTask.h
//  Swift
//
//  Created by Nathaniel Symer on 10/1/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "Task.h"

@interface P2PTask : Task

@property (nonatomic, assign) BOOL isSender;

+ (P2PTask *)taskWithName:(NSString *)name progress:(NSProgress *)progress;

@end
