//
//  DropboxDownload.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/30/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "Download.h"

@interface DropboxDownload : Download

+ (DropboxDownload *)downloadWithPath:(NSString *)path;

@end
