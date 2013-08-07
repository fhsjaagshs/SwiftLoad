//
//  DropboxLinkTask.h
//  Swift
//
//  Created by Nathaniel Symer on 8/6/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "Task.h"

@interface DropboxLinkTask : Task

+ (DropboxLinkTask *)taskWithFilepath:(NSString *)filepath;

@end
