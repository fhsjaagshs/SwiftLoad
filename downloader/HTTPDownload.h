//
//  HTTPDownload.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 7/4/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "Download.h"

@interface HTTPDownload : Download

@property (nonatomic, strong) NSURL *url;

- (id)initWithURL:(NSURL *)aUrl;
+ (HTTPDownload *)downloadWithURL:(NSURL *)aURL;

- (void)resumeFromFailureIfNecessary;

@end
