//
//  BKSessionController.m
//  P2PTest
//
//  Created by boreal-kiss.com on 10/09/15.
//  Copyright 2010 boreal-kiss.com. All rights reserved.
//

#import "BKSessionController.h"
#import "BKChunkDataContainer.h"

// Public
NSString * const BKSessionControllerSenderWillStartSendingDataNotification		= @"BKSessionControllerSenderWillStartSendingData";
NSString * const BKSessionControllerSenderDidFinishSendingDataNotification		= @"BKSessionControllerSenderDidFinishSendingData";
NSString * const BKSessionControllerReceiverWillStartReceivingDataNotification	= @"BKSessionControllerReceiverWillStartReceivingData";
NSString * const BKSessionControllerReceiverDidFinishReceivingDataNotification	= @"BKSessionControllerReceiverDidFinishReceivingData";
NSString * const BKSessionControllerReceiverDidReceiveDataNotification			= @"BKSessionControllerReceiverDidReceiveData";
NSString * const BKSessionControllerPeerDidConnectNotification					= @"BKSessionControllerPeerDidConnect";
NSString * const BKSessionControllerPeerDidDisconnectNotification				= @"BKSessionControllerPeerDidDisconnect";

@interface BKSessionController (_Utilities)
- (void)_sendDataHeaderToAllPeers;
- (void)_sendDataHeaderToPeers:(NSArray *)peers;
- (void)_sendChunkDataCountToAllPeers:(int)count;
- (void)_sendChunkDataCount:(int)count toPeers:(NSArray *)peers;
- (void)_sendDataFooterToAllPeers;
- (void)_sendDataFooterToPeers:(NSArray *)peers;
- (void)_sendChunkData:(NSData *)chunkData toPeers:(NSArray *)peers;
- (void)_sendChunkDataToAllPeers:(NSData *)chunkData;
- (void)_respondsToPeer:(NSString *)peer notificationName:(NSString *)notificationName;
@end

@interface BKSessionController ()
- (void)_senderReceiveData:(NSData *)data fromPeer:(NSString *)peer;
- (void)_receiverReceiveData:(NSData *)data fromPeer:(NSString *)peer;

- (void)_senderWillStartSendingData;
- (void)_senderDidFinishSendingData;
- (void)_receiverWillStartReceivingData;
- (void)_receiverDidFinishReceivingData;
- (void)_receiverDidReceiveData;
- (void)_peerDidConnect;
- (void)_peerDidDisconnect;
@end

@implementation BKSessionController (_Utilities)

- (void)_sendDataHeaderToAllPeers {
	NSData *data = [BKSessionControllerSenderWillStartSendingDataNotification dataUsingEncoding:NSUTF8StringEncoding];
	[self _sendChunkDataToAllPeers:data];
}

- (void)_sendDataHeaderToPeers:(NSArray *)peers {
	NSData *data = [BKSessionControllerSenderWillStartSendingDataNotification dataUsingEncoding:NSUTF8StringEncoding];
	[self _sendChunkData:data toPeers:peers];
}

- (void)_sendChunkDataCountToAllPeers:(int)count {
	NSString *str = [NSString stringWithFormat:@"%d", count];
	NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
	[self _sendChunkDataToAllPeers:data];
}

- (void)_sendChunkDataCount:(int)count toPeers:(NSArray *)peers {
	NSString *str = [NSString stringWithFormat:@"%d", count];
	NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
	[self _sendChunkData:data toPeers:peers];
}

- (void)_sendDataFooterToAllPeers {
	NSData *data = [BKSessionControllerSenderDidFinishSendingDataNotification dataUsingEncoding:NSUTF8StringEncoding];
	[self _sendChunkDataToAllPeers:data];
}

- (void)_sendDataFooterToPeers:(NSArray *)peers {
	NSData *data = [BKSessionControllerSenderDidFinishSendingDataNotification dataUsingEncoding:NSUTF8StringEncoding];
	[self _sendChunkData:data toPeers:peers];
}

- (void)_sendChunkData:(NSData *)chunkData toPeers:(NSArray *)peers {
	NSError *error = nil;
	BOOL queued = [_session sendData:chunkData toPeers:peers withDataMode:GKSendDataReliable error:&error];
	
	if (!queued){
		NSLog(@"Method:%s  Error:%@", __FUNCTION__, [error localizedDescription]);
	}
}

- (void)_sendChunkDataToAllPeers:(NSData *)chunkData {
	NSError *error = nil;
	BOOL queued = [_session sendDataToAllPeers:chunkData withDataMode:GKSendDataReliable error:&error];
	
	if (!queued){
		NSLog(@"Method:%s  Error:%@", __FUNCTION__, [error localizedDescription]);
	}
}

- (void)_respondsToPeer:(NSString *)peer notificationName:(NSString *)notificationName {
	NSData *notificationData = [notificationName dataUsingEncoding:NSUTF8StringEncoding];
	NSArray *peers = [NSArray arrayWithObjects:peer, nil];
	[self _sendChunkData:notificationData toPeers:peers];
}

@end

@implementation BKSessionController
@synthesize session = _session;
@synthesize delegate = _delegate;
@synthesize receivedData = _receivedData;
@synthesize progress = _progress;
@synthesize isSender = _isSender;

//
// DelegateSupport
//

- (void)_senderWillStartSendingData {
	
	NSNotification *aNotification = [NSNotification notificationWithName:BKSessionControllerSenderWillStartSendingDataNotification object:self];
	[[NSNotificationCenter defaultCenter]postNotification:aNotification];
	
	if ([_delegate respondsToSelector:@selector(sessionControllerSenderWillStartSendingData:)]){
		[_delegate sessionControllerSenderWillStartSendingData:aNotification];
	}
}

- (void)_senderDidFinishSendingData {
	
	NSNotification *aNotification = [NSNotification notificationWithName:BKSessionControllerSenderDidFinishSendingDataNotification object:self];
	[[NSNotificationCenter defaultCenter]postNotification:aNotification];
	
	if ([_delegate respondsToSelector:@selector(sessionControllerSenderDidFinishSendingData:)]){
		[_delegate sessionControllerSenderDidFinishSendingData:aNotification];
	}
}

- (void)_receiverWillStartReceivingData {
	NSNotification *aNotification = [NSNotification notificationWithName:BKSessionControllerReceiverWillStartReceivingDataNotification object:self];
	[[NSNotificationCenter defaultCenter]postNotification:aNotification];
	
	if ([_delegate respondsToSelector:@selector(sessionControllerReceiverWillStartReceivingData:)]){
		[_delegate sessionControllerReceiverWillStartReceivingData:aNotification];
	}
}

- (void)_receiverDidFinishReceivingData {
	NSNotification *aNotification = [NSNotification notificationWithName:BKSessionControllerReceiverDidFinishReceivingDataNotification object:self];
	[[NSNotificationCenter defaultCenter]postNotification:aNotification];
	
	if ([_delegate respondsToSelector:@selector(sessionControllerReceiverDidFinishReceivingData:)]){
		[_delegate sessionControllerReceiverDidFinishReceivingData:aNotification];
	}
}

- (void)_receiverDidReceiveData {
	
	NSNotification *aNotification = [NSNotification notificationWithName:BKSessionControllerReceiverDidReceiveDataNotification object:self];
	[[NSNotificationCenter defaultCenter]postNotification:aNotification];
	
	if ([_delegate respondsToSelector:@selector(sessionControllerReceiverDidReceiveData:)]){
		[_delegate sessionControllerReceiverDidReceiveData:aNotification];
	}
}

- (void)_peerDidConnect {
	NSNotification *aNotification = [NSNotification notificationWithName:BKSessionControllerPeerDidConnectNotification object:self];
	[[NSNotificationCenter defaultCenter]postNotification:aNotification];
	
	if ([_delegate respondsToSelector:@selector(sessionControllerPeerDidConnect:)]){
		[_delegate sessionControllerPeerDidConnect:aNotification];
	}
}

- (void)_peerDidDisconnect {
	NSNotification *aNotification = [NSNotification notificationWithName:BKSessionControllerPeerDidDisconnectNotification object:self];
	[[NSNotificationCenter defaultCenter]postNotification:aNotification];
	
	if ([_delegate respondsToSelector:@selector(sessionControllerPeerDidDisconnect:)]){
		[_delegate sessionControllerPeerDidDisconnect:aNotification];
	}
}

//
// GKSessionDelegate
//

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state {
	switch (state) {
		case GKPeerStateConnected:
			[self _peerDidConnect];
            NSLog(@"Connected to peer:%@",peerID);
			break;
		case GKPeerStateDisconnected:
			[self disconnect];
			[self _peerDidDisconnect];
            NSLog(@"Disconnected from peer:%@",peerID);
			break;
		default:
			break;
	}
}

//
// Init Methods
//

+ (id)sessionControllerWithSession:(GKSession *)session{
	return [[[BKSessionController alloc]initWithSession:session]autorelease];
}

- (void)setIsSender:(BOOL)yn {
	_isSender = yn;
	[_session setDataReceiveHandler:self withContext:[NSNumber numberWithBool:_isSender]];
}

- (BOOL)isSender {
	return _isSender;
}

- (id)initWithSession:(GKSession *)session {
	if (self = [super init]) {
		self.session = session;
		_session.delegate = self;
		self.isSender = NO;
	}
	return self;
}

- (void)sendData:(NSData *)data toPeers:(NSArray *)peers {
	
	self.isSender = YES;
	
	// Sends header data.
	[self _sendDataHeaderToPeers:peers];
	
	// Creates chunk data.
	BKChunkDataContainer *dataContainer = [BKChunkDataContainer chunkDataContainerWithData:data];
	int iMax = [dataContainer count];
	
	// Sends count data.
	[self _sendChunkDataCount:iMax toPeers:peers];
	
	// Sends actual data.
	for (int i=0; i<iMax; i++) {
		[self _sendChunkData:[dataContainer chunkDataAtIndex:i] toPeers:peers];
	}
	
	// Sends footer data.
	[self _sendDataFooterToPeers:peers];
}

- (void)sendDataToAllPeers:(NSData *)data {
    
	self.isSender = YES;
	
	// Sends header data.
	[self _sendDataHeaderToAllPeers];
	
	// Creates chunk data.
	BKChunkDataContainer *dataContainer = [BKChunkDataContainer chunkDataContainerWithData:data];
	int iMax = [dataContainer count];
	
	// Sends count data.
	[self _sendChunkDataCountToAllPeers:iMax];
	
	// Sends actual data.
	for (int i=0; i<iMax; i++) {
		[self _sendChunkDataToAllPeers:[dataContainer chunkDataAtIndex:i]];
	}
	
	// Sends footer data.
	[self _sendDataFooterToAllPeers];
}

- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession: (GKSession *)session context:(void *)context{
	
	NSString *str = [[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]autorelease];
	
	// The receiver receives header data.
	if ([str isEqualToString:BKSessionControllerSenderWillStartSendingDataNotification]) {
		self.isSender = NO;
	}
	
	if (_isSender) {
		[self _senderReceiveData:data fromPeer:peer];
	} else {
		[self _receiverReceiveData:data fromPeer:peer];
	}
}

- (void)disconnect {
	[_session disconnectFromAllPeers];
	_session.available = NO;
	[_session setDataReceiveHandler:nil withContext:nil];
	_session.delegate = nil;
	self.session = nil;
}

- (void)dealloc {
	self.delegate = nil;
	self.session = nil;
	self.receivedData = nil;
	[super dealloc];
}

#pragma mark -
#pragma mark Private

//
// Receives responses from the data receiver.
//
-(void)_senderReceiveData:(NSData *)data fromPeer:(NSString *)peer{
	NSString *str = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	
	// The sender receives the first response from the receiver.
	if ([str isEqualToString:BKSessionControllerReceiverWillStartReceivingDataNotification]){
		[self _senderWillStartSendingData];
		return;
	}
	
	// The sender receives the last response from the receiver.
	if ([str isEqualToString:BKSessionControllerReceiverDidFinishReceivingDataNotification]){
		[self _senderDidFinishSendingData];
		return;
	}
    
    
    BOOL isNumeric = NO;
    
    const char *raw = (const char *)[str UTF8String];
    
	for (int i = 0; i < strlen(raw); i++) {
		if (raw[i] < '0' || raw[i] > '9') {
            isNumeric = YES;
        }
	}
    
    if (isNumeric) {
        _progress = [str floatValue];
        if ([_delegate respondsToSelector:@selector(sessionControllerSenderDidReceiveData)]){
            [_delegate sessionControllerSenderDidReceiveData];
        }
        return;
    }
}

//
// Receives data from the sender.
//
- (void)_receiverReceiveData:(NSData *)data fromPeer:(NSString *)peer {
	static BOOL haveChunkDataCount = NO;
	static int totalChunkDataCount = 0;
	static int currentChunkDataCount = 0;
	
	NSString *str = [[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]autorelease];
	
	// The receiver receives header data.
	if ([str isEqualToString:BKSessionControllerSenderWillStartSendingDataNotification]) {
		_receivedData = [[NSMutableData alloc]init];
		_progress = 0.0;
		haveChunkDataCount = NO;
		
		[self _respondsToPeer:peer notificationName:BKSessionControllerReceiverWillStartReceivingDataNotification];
		[self _receiverWillStartReceivingData];
		return;
	}
	
	// The receiver receives footer data.
	if ([str isEqualToString:BKSessionControllerSenderDidFinishSendingDataNotification]) {
		[self _respondsToPeer:peer notificationName:BKSessionControllerReceiverDidFinishReceivingDataNotification];
		[self _receiverDidFinishReceivingData];
		return;
	}
	
	// The receiver receives chunk data count.
	if (!haveChunkDataCount) {
		totalChunkDataCount = [str intValue];
		currentChunkDataCount = 0;
		haveChunkDataCount = YES;
		return;
	}
	
	// Data transmission in progress.
	if (_receivedData) {
		[_receivedData appendData:data];
		currentChunkDataCount++;
		_progress = (float)currentChunkDataCount/totalChunkDataCount;
		[_session sendDataToAllPeers:[[NSString stringWithFormat:@"%f",_progress]dataUsingEncoding:NSUTF8StringEncoding] withDataMode:GKSendDataReliable error:nil];
		[self _receiverDidReceiveData];
	}
}

@end
