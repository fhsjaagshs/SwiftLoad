//
//  BluetoothReceptionTask.h
//  Swift
//
//  Created by Nathaniel Symer on 7/29/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "Task.h"

@interface BluetoothTask : Task

+ (BluetoothTask *)taskWithFile:(NSString *)file;
+ (BluetoothTask *)receiverTaskWithFilename:(NSString *)filename;

@property (nonatomic, assign) BOOL isReceiver;

@end
