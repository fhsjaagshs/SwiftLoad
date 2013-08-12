//
//  BluetoothReceptionTask.m
//  Swift
//
//  Created by Nathaniel Symer on 7/29/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "BluetoothTask.h"

@interface BluetoothTask ()

@property (nonatomic, strong) NSString *file;

@end

@implementation BluetoothTask

+ (BluetoothTask *)receiverTaskWithFilename:(NSString *)filename {
    BluetoothTask *task = [[[self class]alloc]initWithFilename:filename];
    task.isReceiver = YES;
    return task;
}

+ (BluetoothTask *)taskWithFile:(NSString *)file {
    return [[[self class]alloc]initWithFile:file];
}

- (BOOL)canStop {
    return YES;
}

- (NSString *)verb {
    return [[BluetoothManager sharedManager]isSender]?@"Sending":@"Receiving";
}

- (instancetype)initWithFilename:(NSString *)filename {
    self = [super init];
    if (self) {
        self.name = filename;
        [self setup];
    }
    return self;
}

- (instancetype)initWithFile:(NSString *)file {
    self = [super init];
    if (self) {
        self.name = file.lastPathComponent;
        self.file = file;
        [self setup];
    }
    return self;
}

- (void)removeBTManagerCallbacks {
    [[BluetoothManager sharedManager]setProgressBlock:nil];
    [[BluetoothManager sharedManager]setCompletionBlock:nil];
}

- (void)showFailure {
    [super showFailure];
    [self removeBTManagerCallbacks];
}

- (void)showSuccess {
    [super showSuccess];
    [self removeBTManagerCallbacks];
}

- (void)stop {
    [super stop];
    [self removeBTManagerCallbacks];
    [[BluetoothManager sharedManager]cancel];
}

- (void)start {
    [super start];
    
    if (!_isReceiver) {
        [[BluetoothManager sharedManager]loadFile:_file];
        [[BluetoothManager sharedManager]searchForPeers];
    }
}

- (void)setup {
    __weak BluetoothTask *weakself = self;
    
    [[BluetoothManager sharedManager]setProgressBlock:^(float progress) {
        [weakself.delegate setProgress:progress];
    }];
    
    [[BluetoothManager sharedManager]setCompletionBlock:^(NSError *error, BOOL cancelled) {
        if (!cancelled) {
            if (!error) {
                [weakself showSuccess];
            } else {
                [weakself showFailure];
            }
        } else {
            [self stop];
        }
    }];
}

@end
