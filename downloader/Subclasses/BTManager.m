//
//  BTManager.m
//  Swift
//
//  Created by Nathaniel Symer on 9/30/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "BTManager.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import <objc/runtime.h>

static NSString * const kServiceType = @"SwiftBluetooth";

@interface MCPeerID (swift_key)

- (NSString *)keyWithResourceName:(NSString *)name;

@end

@implementation MCPeerID (swift_key)

- (NSString *)keyWithResourceName:(NSString *)name {
    return [NSString stringWithFormat:@"%@-%@",self.displayName,name];
}

@end

@interface BTManager () <MCSessionDelegate, MCBrowserViewControllerDelegate>

@property (nonatomic, strong) MCSession *session;
@property (nonatomic, strong) MCAdvertiserAssistant *advertiserAssistant;
@property (nonatomic, strong) NSMutableDictionary *sendingObjs;
@property (nonatomic, strong) NSMutableDictionary *receivingObjs;

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
        self.sendingObjs = [NSMutableDictionary dictionary];
        self.receivingObjs = [NSMutableDictionary dictionary];
        self.session = [[MCSession alloc]initWithPeer:[[MCPeerID alloc]initWithDisplayName:[[UIDevice currentDevice]systemName]] securityIdentity:nil encryptionPreference:MCEncryptionRequired];
        _session.delegate = self;
        self.advertiserAssistant = [[MCAdvertiserAssistant alloc]initWithServiceType:kServiceType discoveryInfo:nil session:_session];
        [_advertiserAssistant start];
    }
    return self;
}

- (void)prepareForBackground {
    [_advertiserAssistant stop];
}

- (void)prepareForForeground {
    [_advertiserAssistant start];
}

- (void)sendFileAtPath:(NSString *)path {
    [_advertiserAssistant stop];
    MCNearbyServiceBrowser *browser = [[MCNearbyServiceBrowser alloc]initWithPeer:_session.myPeerID serviceType:kServiceType];
    MCBrowserViewController *browserVC = [[MCBrowserViewController alloc]initWithBrowser:browser session:_session];
    browserVC.delegate = self;
    browserVC.maximumNumberOfPeers = 1;
    browserVC.minimumNumberOfPeers = 1;
    objc_setAssociatedObject(browserVC, "passed_path_swift", path, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController {
    NSString *path = (NSString *)objc_getAssociatedObject(browserViewController, "passed_path_swift");
    
    for (MCPeerID *peerID in _session.connectedPeers) {
        NSProgress *progress = [_session sendResourceAtURL:[NSURL URLWithString:path] withName:path.lastPathComponent toPeer:nil withCompletionHandler:^(NSError *error) {
            if (_sendingObjs[[peerID keyWithResourceName:path.lastPathComponent]]) {
                [_sendingObjs removeObjectForKey:[peerID keyWithResourceName:path.lastPathComponent]];
            }
            
            if (_sendingObjs.count == 0) {
                [_advertiserAssistant start];
            }
        }];
        
        P2PTask *task = [P2PTask taskWithName:path.lastPathComponent progress:progress];
        task.isSender = YES;
        _sendingObjs[[peerID keyWithResourceName:path.lastPathComponent]] = task;
    }
}

- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController {
    if (_sendingObjs.count == 0) {
        [_advertiserAssistant start];
    }
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error {
    
    if (_sendingObjs.count == 0) {
        [_advertiserAssistant start];
    }
    
    if (error) {
        [(P2PTask *)_receivingObjs[[peerID keyWithResourceName:resourceName]] showFailure];
    } else {
        NSString *movedToPath = getNonConflictingFilePathForPath([kDocsDir stringByAppendingPathComponent:localURL.path.lastPathComponent]);
        [[NSFileManager defaultManager]moveItemAtPath:localURL.path toPath:movedToPath error:nil];
        [(P2PTask *)_receivingObjs[[peerID keyWithResourceName:resourceName]] showSuccess];
    }
    
    if (_receivingObjs[[peerID keyWithResourceName:resourceName]]) {
        [_receivingObjs removeObjectForKey:[peerID keyWithResourceName:resourceName]];
    }
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress {
    P2PTask *task = [P2PTask taskWithName:resourceName progress:progress];
    task.isSender = NO;
    _receivingObjs[[peerID keyWithResourceName:resourceName]] = task;
    [_advertiserAssistant stop];
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
