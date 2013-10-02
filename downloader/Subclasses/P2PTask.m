//
//  P2PTask.m
//  Swift
//
//  Created by Nathaniel Symer on 10/1/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "P2PTask.h"

static NSString * const kProgressCancelledKeyPath = @"cancelled";
static NSString * const kProgressCompletedUnitCountKeyPath = @"completedUnitCount";

@interface P2PTask ()

@property (nonatomic, strong) NSProgress *progress;
@property (nonatomic, strong) NSString *name;

@end

@implementation P2PTask

- (NSString *)verb {
    return _isSender?@"Sending...":@"Receiving...";
}

+ (P2PTask *)taskWithName:(NSString *)name progress:(NSProgress *)progress  {
    return [[[self class]alloc]initWithName:name progress:progress];
}

- (instancetype)initWithName:(NSString *)name progress:(NSProgress *)progress {
    self = [super init];
    if (self) {
        self.name = name;
        self.progress = progress;
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([(NSProgress *)object isEqual:self]) {
        if ([keyPath isEqualToString:kProgressCancelledKeyPath]) {
           // [_delegate progressDidCancel:self];
        } else if ([keyPath isEqualToString:kProgressCompletedUnitCountKeyPath]) {
            if (self.progress.completedUnitCount == self.progress.totalUnitCount) {
               // [_delegate progressDidFinish:self];
            } else {
                // [_delegate progressDidProgress:self];
            }
        }
    }
}

- (void)dealloc {
    [_progress removeObserver:self forKeyPath:kProgressCancelledKeyPath];
    [_progress removeObserver:self forKeyPath:kProgressCompletedUnitCountKeyPath];
    self.progress = nil;
}

@end
