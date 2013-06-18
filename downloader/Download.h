//
//  Download.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/17/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Download : NSObject

@property (nonatomic, assign) float fileSize;
@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, strong) NSURL *url;

- (void)stop;
- (void)start;

- (id)initWithURL:(NSURL *)aUrl;
+ (Download *)downloadWithURL:(NSURL *)aURL;

@end
