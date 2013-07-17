//
//  BluetoothManager.h
//  Swift
//
//  Created by Nathaniel Symer on 7/15/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

/*typedef void (^progressBlock)(float progress);
typedef void (^startedBlock)(void);
typedef void (^finishBlock)(BOOL succeeded,BOOLcancelled);*/

@interface BluetoothManager : NSObject

+ (BluetoothManager *)sharedManager;

- (void)cancel;

- (void)prepareForBackground;
- (void)prepareForForeground;

- (void)searchForPeers;
- (void)loadFile:(NSString *)path;
- (NSString *)getFilename;

@property (nonatomic, copy) void(^progressBlock)(float progress);
@property (nonatomic, copy) void(^completionBlock)(NSError *error,BOOL cancelled);
@property (nonatomic, copy) void(^startedBlock)(void);

@property (nonatomic, assign) BOOL isSender;

@end
