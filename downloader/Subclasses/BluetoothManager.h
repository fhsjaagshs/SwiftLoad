//
//  BluetoothManager.h
//  Swift
//
//  Created by Nathaniel Symer on 7/15/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^progressBlock)(float progress);
typedef void (^startedBlock)();
typedef void (^finishBlock)(BOOL succeeded, BOOL cancelled);

@interface BluetoothManager : NSObject

+ (BluetoothManager *)sharedManager;

- (void)cancel;
- (void)searchForPeers;
- (void)loadFile:(NSString *)path;
- (NSString *)getFilename;

@property (nonatomic, copy) progressBlock progressBlock;
@property (nonatomic, copy) finishBlock completionBlock;
@property (nonatomic, copy) startedBlock startedBlock;

@end
