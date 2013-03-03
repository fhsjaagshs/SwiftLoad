//
//  BKSessionController.h
//  P2PTest
//
//  Created by boreal-kiss.com on 10/09/15.
//  Copyright 2010 boreal-kiss.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

extern NSString * const BKSessionControllerSenderWillStartSendingDataNotification;
extern NSString * const BKSessionControllerSenderDidFinishSendingDataNotification;
extern NSString * const BKSessionControllerReceiverWillStartReceivingDataNotification;
extern NSString * const BKSessionControllerReceiverDidFinishReceivingDataNotification;
extern NSString * const BKSessionControllerReceiverDidReceiveDataNotification;
extern NSString * const BKSessionControllerPeerDidConnectNotification;
extern NSString * const BKSessionControllerPeerDidDisconnectNotification;

@protocol BKSessionControllerDelegate;

@interface BKSessionController : NSObject <GKSessionDelegate> {
	GKSession *_session;
	NSMutableData *_receivedData;
	id <BKSessionControllerDelegate> _delegate;
	CGFloat _progress;
	BOOL _isSender;
}

// A GKSession object controlled by the BKSessionController.
@property (nonatomic, retain) GKSession *session;
@property (nonatomic, assign) id <BKSessionControllerDelegate> delegate;


// Received data from a remote peer.
@property (nonatomic, retain) NSMutableData *receivedData;

// The current progress represented by a floating-point value between 0.0 and 1.0, inclusive.
// If no data received, the value is 0.0.
@property (nonatomic, readonly) CGFloat progress;

// A BOOL that is used to determine if you are the sender.
@property (nonatomic, assign) BOOL isSender;

// The convenience method.
+ (id)sessionControllerWithSession:(GKSession *)session;

// The designated initializer.
- (id)initWithSession:(GKSession *)session;

// Sends data in any size to given peers.
// This is the same interface/functionality as that found in a GKSession object.
- (void)sendData:(NSData *)data toPeers:(NSArray *)peers;

// Sends data in any size to all peers.
// This is the same interface/functionality as that found in a GKSession object.
- (void)sendDataToAllPeers:(NSData *)data;

// A data receiving handler.
// This is the same interface/functionality as that required in a GKSession object's handler.
- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession:(GKSession *)session context:(void *)context;

// Disconnects the session from all connected peers.
- (void)disconnect;

@end


@protocol BKSessionControllerDelegate <NSObject>

@optional
- (void)sessionControllerSenderWillStartSendingData:(NSNotification *)aNotification;
- (void)sessionControllerSenderDidReceiveData;
- (void)sessionControllerSenderDidFinishSendingData:(NSNotification *)aNotification;
- (void)sessionControllerReceiverWillStartReceivingData:(NSNotification *)aNotification;
- (void)sessionControllerReceiverDidFinishReceivingData:(NSNotification *)aNotification;
- (void)sessionControllerReceiverDidReceiveData:(NSNotification *)aNotification;
- (void)sessionControllerPeerDidConnect:(NSNotification *)aNotification;
- (void)sessionControllerPeerDidDisconnect:(NSNotification *)aNotification;

@end
