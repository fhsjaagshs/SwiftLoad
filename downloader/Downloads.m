//
//  Downloads.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/17/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "Downloads.h"

@interface Downloads ()

@property (nonatomic, strong) NSMutableArray *downloadObjs;

@end

@implementation Downloads

- (int)indexOfDownload:(Download *)download {
    return [_downloadObjs indexOfObject:download];
}

- (int)numberDownloads {
    return _downloadObjs.count;
}

- (void)removeAllDownloads {
    for (Download *download in _downloadObjs) {
        [self removeDownload:download];
    }
}

- (void)removeDownload:(Download *)download {
    [download stop];
    [_downloadObjs removeObject:download];
}

- (void)addDownload:(Download *)download {
    [_downloadObjs addObject:download];
    [download start];
}

- (void)removeDownloadAtIndex:(int)index {
    [self removeDownload:[_downloadObjs objectAtIndex:index]];
}

- (Download *)downloadAtIndex:(int)index {
    return [_downloadObjs objectAtIndex:index];
}

- (int)tagForDownload:(Download *)download {
    return [_downloadObjs indexOfObject:download];
}

- (id)init {
    self = [super init];
    if (self) {
        self.downloadObjs = [NSMutableArray array];
    }
    return self;
}

//
// Singleton Stuff
//

+ (Downloads *)sharedDownloads {
    static Downloads *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[Downloads alloc]init];
    });
    
    return shared;
}


@end
