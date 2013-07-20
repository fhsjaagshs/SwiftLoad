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

- (void)updateButtonNumber:(int)number;

- (void)removeAllDownloads;
- (void)removeDownload:(Download *)download;
- (void)addDownload:(Download *)download;

- (void)removeDownloadAtIndex:(int)index;

- (Download *)downloadAtIndex:(int)index;
- (int)indexOfDownload:(Download *)download;

- (int)numberDownloads;

+ (DownloadController *)sharedController;

@end
