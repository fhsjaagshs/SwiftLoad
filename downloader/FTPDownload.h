//
//  FTPDowload.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 7/4/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "Download.h"

@interface FTPDownload : Download

@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSURL *url;

+ (FTPDownload *)downloadWithURL:(NSURL *)aURL;

@end
