//
//  PeerPicker.h
//  Swift
//
//  Created by Nathaniel Symer on 7/16/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

@interface PeerPicker : UIAlertView

+ (PeerPicker *)peerPicker;

@property (nonatomic, strong)  NSMutableArray *ignoredPeerIDs;

@property (nonatomic, copy) void(^peerPickedBlock)(NSString *peerID);
@property (nonatomic, copy) void(^cancelledBlock)();

@end
