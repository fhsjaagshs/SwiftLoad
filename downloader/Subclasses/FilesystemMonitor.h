//
//  FilesystemMonitor.h
//  Swift
//
//  Created by Nathaniel Symer on 7/21/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FilesystemMonitor : NSObject

+ (FilesystemMonitor *)sharedMonitor;
- (BOOL)startMonitoringDirectory:(NSString *)dirPath;
- (void)invalidate;

@property (nonatomic, copy) void(^changedHandler)();

@end
