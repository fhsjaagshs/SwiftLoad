//
//  DBRestClient+SpecificCancellation.h
//  Swift
//
//  Created by Nathaniel Symer on 9/13/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "DropboxSDK.h"

@interface DBRestClient (SpecificCancellation)

- (int)cancelAllDownloads;
- (int)cancelAllMiscRequests;

- (BOOL)cancelUploadWithDropboxPath:(NSString *)dbPath;
- (BOOL)cancelDownloadWithDropboxPath:(NSString *)dbPath;
- (BOOL)cancelSharableLinkLoadWithDropboxPath:(NSString *)dbPath;

@end
