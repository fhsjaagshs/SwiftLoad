//
//  Download.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/17/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kDownloadChanged;

@class DownloadingCell;

@interface Download : NSObject

@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, strong) NSString *temporaryPath;
@property (nonatomic, assign) BOOL complete;
@property (nonatomic, assign) BOOL succeeded;

@property (nonatomic, weak) DownloadingCell *delegate;

- (void)stop;
- (void)start;

- (void)showSuccess;
- (void)showFailure;

- (void)handleBackgroundTaskExpiration;

@end