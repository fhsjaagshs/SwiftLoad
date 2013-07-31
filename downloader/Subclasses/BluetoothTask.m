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

+ (BluetoothTask *)taskWithFile:(NSString *)file {
    return [[[self class]alloc]initWithFile:file];
}

- (BOOL)canStop {
    return YES;
}

- (id)initWithFile:(NSString *)file {
    self = [super init];
    if (self) {
        self.file = file;
        [self setup];
    }
    return self;
}

- (void)stop {
    [super stop];
    [[BluetoothManager sharedManager]cancel];
}

- (void)start {
    [super start];
    [[BluetoothManager sharedManager]loadFile:_file];
    [[BluetoothManager sharedManager]searchForPeers];
}

- (void)setup {
    
    __weak BluetoothTask *weakself = self;
    
    self.name = [NSString stringWithFormat:@"%@: %@",[[BluetoothManager sharedManager]isSender]?@"Sending":@"Receiving",[[BluetoothManager sharedManager]getFilename]];
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
        }
    }];
}

@end
