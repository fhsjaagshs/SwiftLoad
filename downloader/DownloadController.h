//
//  DownloadController.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/18/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DownloadController : UIView

- (void)hide;
- (void)show;

- (void)removeAllDownloads;
- (void)removeDownload:(Download *)download;
- (void)addDownload:(Download *)download;

- (void)removeDownloadAtIndex:(int)index;

- (int)indexOfDownload:(Download *)download;

+ (DownloadController *)sharedController;

@end
