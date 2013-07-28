//
//  UnzippingTask.h
//  Swift
//
//  Created by Nathaniel Symer on 7/28/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "Task.h"

@interface UnzippingTask : Task

+ (UnzippingTask *)taskWithFile:(NSString *)file;

@end
