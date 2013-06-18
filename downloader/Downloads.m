//
//  Downloads.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/17/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "Downloads.h"

static Downloads *sharedInstance = nil;

@interface Downloads ()

@property (nonatomic, retain) NSMutableArray *downloadObjs;

@end

@implementation Downloads

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
    [download start];
    [_downloadObjs addObject:download];
}

- (void)removeDownloadAtIndex:(int)index {
    [self removeDownload:[_downloadObjs objectAtIndex:index]];
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

// The shared* class method
+ (Downloads *)sharedDownloads {
    @synchronized (self) {
        if (sharedInstance == nil) {
            [[self alloc]init];
        }
    }
    return sharedInstance;
}

// Override stuff to make sure that the singleton is never dealloc'd. Fun.
+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedInstance == nil) {
            sharedInstance = [super allocWithZone:zone];
            return sharedInstance;
        }
    }
    return nil;
}

- (id)retain {
    return self;
}

- (oneway void)release {
    // Do nothing
}

- (id)autorelease {
    return self;
}

- (NSUInteger)retainCount {
    return NSUIntegerMax;
}

- (void)dealloc {
    [self setDownloadObjs:nil];
    [super dealloc];
}

@end
