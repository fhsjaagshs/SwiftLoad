//
//  BluetoothManager.m
//  Swift
//
//  Created by Nathaniel Symer on 7/15/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "BluetoothManager.h"
#import <GameKit/GameKit.h>
#import "PeerPicker.h"

static NSString *kFlagKey = @"f";
static NSString *kDataKey = @"d";
static NSString *kFilenameKey = @"n";
static NSString *kFilesizeKey = @"s";

@interface BluetoothManager () <GKSessionDelegate>

@property (nonatomic, assign) float filesize;
@property (nonatomic, assign) float receivedBytes;
@property (nonatomic, strong) NSString *targetPath;

@property (nonatomic, strong) GKSession *session;
@property (nonatomic, strong) NSString *filename;
@property (nonatomic, strong) NSFileHandle *handle;

@property (nonatomic, assign) float readBytes;
@property (nonatomic, strong) NSString *originFilePath;

@property (nonatomic, strong) PeerPicker *picker;

@property (nonatomic, assign) BOOL isTransferring;

@end

@implementation BluetoothManager

+ (BluetoothManager *)sharedManager {
    static BluetoothManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc]init];
    });
    return manager;
}

- (id)init {
    self = [super init];
    if (self) {
        self.picker = [PeerPicker peerPicker];
        self.session = [[GKSession alloc]initWithSessionID:@"swift_bluetooth" displayName:nil sessionMode:GKSessionModePeer];
        [_session setDataReceiveHandler:self withContext:nil];
        _session.delegate = self;
        _session.available = YES;
        [_picker.ignoredPeerIDs addObject:_session.peerID];
    }
    return self;
}

- (void)finish {
    self.isTransferring = NO;
    [_session disconnectFromAllPeers];
    if (_completionBlock) {
        _completionBlock(YES,NO);
    }
    [self reset];
}

- (void)fail {
    [_session disconnectFromAllPeers];
    if (_completionBlock) {
        _completionBlock(NO,NO);
    }
    [self reset];
}

- (void)cancel {
    [_session disconnectFromAllPeers];
    if (_completionBlock) {
        _completionBlock(NO,YES);
    }
    [self reset];
}

- (void)reset {
    _session.available = YES;
    _picker.state = PeerPickerStateNormal;
    self.originFilePath = nil;
    self.isSender = NO;
    self.readBytes = 0;
    self.filesize = 0;
    self.filename = nil;
    self.handle = nil;
    self.receivedBytes = 0;
    self.targetPath = nil;
    self.isTransferring = NO;
}

- (void)searchForPeers {
    self.isSender = YES;
    self.isTransferring = YES;
    _picker.state = PeerPickerStateNormal;
    __weak BluetoothManager *weakManager = self;
    [_picker setPeerPickedBlock:^(NSString *peerID) {
        weakManager.isSender = YES;
        [weakManager.session connectToPeer:peerID withTimeout:30];
        [weakManager.picker setState:PeerPickerStateConnecting];
    }];
    
    [_picker setCancelledBlock:^{
        weakManager.isSender = NO;
        weakManager.session.available = YES;
        [weakManager reset];
    }];
    [_picker show];
}

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state {
    switch (state) {
        case GKPeerStateDisconnected: {
            _session.available = YES;
            if (_isTransferring) {
                [TransparentAlert showAlertWithTitle:@"Bluetooth Disconnected" andMessage:@"You have been disconnected from the other iPhone."];
                [self fail];
            }
        } break;
        case GKPeerStateConnected: {
            
            [_picker dismissWithClickedButtonIndex:0 animated:YES];
            
            _session.available = NO;
            
            if (_startedBlock) {
                _startedBlock();
            }
            
            if (_isSender) {
                [self sendData:[self info]];
            }
        } break;
        default:
            break;
    }
}

- (void)session:(GKSession *)session didFailWithError:(NSError *)error {
    if (self.isTransferring) {
        [TransparentAlert showAlertWithTitle:@"Bluetooth Error" andMessage:error.localizedDescription];
        [self fail];
    }
}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID {
    self.isSender = NO;
    NSLog(@"Received From sender: %@",[_session displayNameForPeer:peerID]);
    [[[TransparentAlert alloc]initWithTitle:@"Connect?" message:[NSString stringWithFormat:@"Would you like to connect to %@",[_session displayNameForPeer:peerID]] completionBlock:^(NSUInteger buttonIndex, UIAlertView *alertView) {
        if (buttonIndex == 1) {
            [_session acceptConnectionFromPeer:peerID error:nil];
        } else {
            [_session denyConnectionFromPeer:peerID];
        }
    } cancelButtonTitle:@"No" otherButtonTitles:@"YES", nil]show];
}

- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error {
    if (self.isTransferring) {
        [TransparentAlert showAlertWithTitle:@"Bluetooth Connection Failed" andMessage:error.localizedDescription];
        [self fail];
    }
}

- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession:(GKSession *)session context:(void *)context {
    [self handleData:data];
}

//
// File/Data management
//

- (NSString *)getFilename {
    return _filename;
}

- (void)loadFile:(NSString *)path {
    self.filename = [path lastPathComponent];
    self.originFilePath = path;
    self.handle = [NSFileHandle fileHandleForReadingAtPath:_originFilePath];
    self.filesize = [[[NSFileManager defaultManager]attributesOfItemAtPath:_originFilePath error:nil]fileSize];
}

- (NSData *)readData {
    [_handle seekToFileOffset:_readBytes];
    NSData *data = [_handle readDataOfLength:80000];
    _readBytes += data.length;
    return data;
}

- (void)writeData:(NSData *)data {
    [_handle seekToEndOfFile];
    [_handle writeData:data];
}

- (NSData *)info {
    return [NSKeyedArchiver archivedDataWithRootObject:@{ kFlagKey: @"info", kFilenameKey: _filename, kFilesizeKey: [NSNumber numberWithDouble:_filesize] }];
}

- (NSData *)data:(NSData *)data {
    return [NSKeyedArchiver archivedDataWithRootObject:@{ kFlagKey: @"data", kDataKey: data}];
}

- (NSData *)response {
    return [NSKeyedArchiver archivedDataWithRootObject:@ {kFlagKey: @"response" }];
}

- (void)handleData:(NSData *)data {
    
    NSDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    NSString *flag = [dict objectForKey:kFlagKey];
    
    if ([flag isEqualToString:@"info"]) {
        self.isTransferring = YES;
        self.filesize = [[dict objectForKey:kFilesizeKey]floatValue];
        self.filename = [dict objectForKey:kFilenameKey];
        self.targetPath = getNonConflictingFilePathForPath([NSTemporaryDirectory() stringByAppendingPathComponent:_filename]);
        [[NSFileManager defaultManager]createFileAtPath:_targetPath contents:nil attributes:nil];
        self.handle = [NSFileHandle fileHandleForWritingAtPath:_targetPath];
        
        if (_startedBlock) {
            _startedBlock();
        }
        
        [self sendData:[self response]];
    } else if ([flag isEqualToString:@"data"]) {
        if (!_isSender) {
            NSData *fileData = [dict objectForKey:kDataKey];
            
            self.receivedBytes += fileData.length;
            
            float progress = _receivedBytes/_filesize;
            
            [self writeData:fileData];
            
            if (_progressBlock) {
                _progressBlock(progress);
            }
            
            [self sendData:[self response]];
            
            if (progress == 1) {
                [[NSFileManager defaultManager]moveItemAtPath:_targetPath toPath:getNonConflictingFilePathForPath([kDocsDir stringByAppendingPathComponent:_filename]) error:nil];
                [self finish];
                
                /*self.isTransferring = NO;
                
                
                if (_completionBlock) {
                    _completionBlock(YES,NO);
                }*/
            }
            
        }
    } else if ([flag isEqualToString:@"response"]) {
        if (_isSender) {
            float progress = _readBytes/_filesize;
            
            if (_progressBlock) {
                _progressBlock(progress);
            }
            
            if (progress == 1) {
                [self finish];
                /*if (_completionBlock) {
                    _completionBlock(YES,NO);
                }
                self.isTransferring = NO;*/
            } else {
                [self sendData:[self data:[self readData]]];
            }
        }
    }
}

- (void)sendData:(NSData *)data {
    [_session sendDataToAllPeers:data withDataMode:GKSendDataReliable error:nil];
}


@end
