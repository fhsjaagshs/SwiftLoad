//
//  FTPDowload.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 7/4/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "Download.h"

@interface FTPDownload : Download

@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *password;
@property (nonatomic, retain) NSURL *url;

+ (FTPDownload *)downloadWithURL:(NSURL *)aURL;

@end
