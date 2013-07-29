//
//  BluetoothReceptionTask.m
//  Swift
//
//  Created by Nathaniel Symer on 7/29/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "BluetoothTask.h"

@implementation BluetoothTask

+ (void)sendFile:(NSString *)file {
    [[BluetoothManager sharedManager]loadFile:file];
    [[BluetoothManager sharedManager]searchForPeers];
}

+ (BluetoothTask *)task {
    return [[[self class]alloc]init];
}

- (id)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
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
