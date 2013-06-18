//
//  Downloads.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/17/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Downloads : NSObject

- (void)removeAllDownloads;
- (void)removeDownload:(Download *)download;
- (void)addDownload:(Download *)download;

- (void)removeDownloadAtIndex:(int)index;

- (Download *)downloadAtIndex:(int)index;
- (int)indexOfDownload:(Download *)download;

- (int)numberDownloads;

+ (Downloads *)sharedDownloads;

@end
