//
//  P2PTask.m
//  Swift
//
//  Created by Nathaniel Symer on 10/1/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "P2PTask.h"

static NSString * const kProgressCancelledKeyPath = @"cancelled";
static NSString * const kProgressAdvancedKeyPath = @"fractionCompleted";

@interface P2PTask ()

@property (nonatomic, strong) NSProgress *progress;
@property (nonatomic, strong) NSString *name;

@end

@implementation P2PTask

- (BOOL)canStop {
    return NO;
}

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
        [_progress addObserver:self forKeyPath:kProgressCancelledKeyPath options:NSKeyValueObservingOptionNew context:NULL];
        [_progress addObserver:self forKeyPath:kProgressAdvancedKeyPath options:NSKeyValueObservingOptionNew context:NULL];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([(NSProgress *)object isEqual:_progress]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            @autoreleasepool {
                if ([keyPath isEqualToString:kProgressCancelledKeyPath]) {
                    [self showFailure];
                } else if ([keyPath isEqualToString:kProgressAdvancedKeyPath]) {
                    if (_progress.fractionCompleted == 1.0f) {
                        [self showSuccess];
                    } else {
                        [self.delegate setProgress:_progress.fractionCompleted];
                    }
                }
            }
        });
    }
}

- (void)dealloc {
    [_progress removeObserver:self forKeyPath:kProgressCancelledKeyPath];
    [_progress removeObserver:self forKeyPath:kProgressAdvancedKeyPath];
    self.progress = nil;
}

@end
