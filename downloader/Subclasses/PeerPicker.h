//
//  PeerPicker.h
//  Swift
//
//  Created by Nathaniel Symer on 7/16/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "TransparentAlert.h"

typedef enum {
    PeerPickerStateNormal,
    PeerPickerStateConnecting
} PeerPickerState;

@interface PeerPicker : TransparentAlert

+ (PeerPicker *)peerPicker;

@property (nonatomic, assign, setter = setState:) PeerPickerState state;
@property (nonatomic, strong)  NSMutableArray *ignoredPeerIDs;

@property (nonatomic, copy) void(^peerPickedBlock)(NSString *peerID);
@property (nonatomic, copy) void(^cancelledBlock)();

@end
