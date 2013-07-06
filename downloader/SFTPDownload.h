//
//  SFTPDownload.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 7/6/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "Download.h"

@interface SFTPDownload : Download

+ (SFTPDownload *)downloadWithURL:(NSURL *)url username:(NSString *)username andPassword:(NSString *)password;

@end
