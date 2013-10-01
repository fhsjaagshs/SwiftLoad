//
//  BTManager.m
//  Swift
//
//  Created by Nathaniel Symer on 9/30/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "BTManager.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>

static NSString * const kProgressCancelledKeyPath = @"cancelled";
static NSString * const kProgressCompletedUnitCountKeyPath = @"completedUnitCount";

@protocol BTProgressDelegate;

@interface BTProgress : NSObject

+ (BTProgress *)progressWithName:(NSString *)name progress:(NSProgress *)progress andDelegate:(id<BTProgressDelegate>)aDelegate;

@property (nonatomic, strong) NSProgress *progress;
@property (nonatomic, weak) id<BTProgressDelegate> delegate;

@end

@protocol BTProgressDelegate <NSObject>

@optional
- (void)progressDidFinish:(BTProgress *)progress;
- (void)progressDidCancel:(BTProgress *)progress;
- (void)progressDidProgress:(BTProgress *)progress;

@end

@implementation BTProgress

+ (BTProgress *)progressWithName:(NSString *)name progress:(NSProgress *)progress andDelegate:(id<BTProgressDelegate>)aDelegate {
    return [[[self class]alloc]initWithName:name progress:progress andDelegate:aDelegate];
}

- (instancetype)initWithName:(NSString *)name progress:(NSProgress *)progress andDelegate:(id<BTProgressDelegate>)aDelegate {
    self = [super init];
    if (self) {
        self.
        self.progress = progress;
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([(NSProgress *)object isEqual:self]) {
        if ([keyPath isEqualToString:kProgressCancelledKeyPath]) {
            [_delegate progressDidCancel:self];
        } else if ([keyPath isEqualToString:kProgressCompletedUnitCountKeyPath]) {
            if (self.progress.completedUnitCount == self.progress.totalUnitCount) {
                [_delegate progressDidFinish:self];
            } else {
                [_delegate progressDidProgress:self];
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

@interface BTManager () <MCSessionDelegate, BTProgressDelegate>

@property (nonatomic, strong) MCSession *session;
@property (nonatomic, strong) MCAdvertiserAssistant *advertiserAssistant;
@property (nonatomic, strong) NSMutableDictionary *progressObjs;

@end

@implementation BTManager

+ (BTManager *)shared {
    static BTManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[BTManager alloc]init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.progressObjs = [NSMutableDictionary dictionary];
        self.session = [[MCSession alloc]initWithPeer:[[MCPeerID alloc]initWithDisplayName:[[UIDevice currentDevice]systemName]] securityIdentity:nil encryptionPreference:MCEncryptionRequired];
        _session.delegate = self;
        self.advertiserAssistant = [[MCAdvertiserAssistant alloc]initWithServiceType:@"SwiftBluetooth" discoveryInfo:nil session:_session];
        [_advertiserAssistant start];
    }
    return self;
}

- (BOOL)sendFileAtPath:(NSString *)path {
    for (MCPeerID *perrID in _session.connectedPeers) {
        [_session sendResourceAtURL:[NSURL URLWithString:path] withName:path.lastPathComponent toPeer:nil withCompletionHandler:^(NSError *error) {
            if (_sendingCompletionHandler) {
                _sendingCompletionHandler(error);
            }
        }];
    }
    return _session.connectedPeers.count > 0;
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error {
    [_progressObjs removeObjectForKey:resourceName];
    if (error) {
        if (_receivingCompletionHandler) {
            _receivingCompletionHandler(error, nil);
        }
    } else {
        NSString *movedToPath = getNonConflictingFilePathForPath([kDocsDir stringByAppendingPathComponent:localURL.path.lastPathComponent]);
        [[NSFileManager defaultManager]moveItemAtPath:localURL.path toPath:movedToPath error:nil];
        if (_receivingCompletionHandler) {
            _receivingCompletionHandler(nil, movedToPath);
        }
    }
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress {
    BTProgress *btprogress = [BTProgress progressWithName:resourceName progress:progress andDelegate:self];
    _progressObjs[resourceName] = btprogress;
}

// These cats ain't implemented
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
    
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
    
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID {
    
}

- (void)dealloc {
    [_advertiserAssistant stop];
    [_session disconnect];
}

@end
