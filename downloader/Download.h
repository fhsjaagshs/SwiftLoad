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

@property (nonatomic, retain) NSString *fileName;
@property (nonatomic, assign) BOOL complete;
@property (nonatomic, assign) BOOL succeeded;

@property (nonatomic, assign) DownloadingCell *delegate;

- (void)stop;
- (void)start;

- (void)showSuccess;
- (void)showFailure;

- (void)handleBackgroundTaskExpiration;

@end
