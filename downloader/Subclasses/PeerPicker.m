//
//  PeerPicker.m
//  Swift
//
//  Created by Nathaniel Symer on 7/16/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "PeerPicker.h"
#import "PeerPickerCell.h"

static NSString * const kLongMessage = @"\n\n\n\n\n\n\n\n\n";
static NSString * const kShortMessage = @"\n\n\n";

static NSString * const kCellID = @"PeerPicker";

@interface PeerPicker () <GKSessionDelegate, UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) GKSession *session;
@property (nonatomic, strong) UITableView *theTableView;
@property (nonatomic, strong) UIImageView *theImageView;
@property (nonatomic, strong) UILabel *searchingLabel;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) NSMutableArray *peers;

@end

@implementation PeerPicker

- (void)setState:(PeerPickerState)state {
    _state = state;
    self.message = (state == PeerPickerStateNormal)?kLongMessage:kShortMessage;
    [self setNeedsLayout];
}

+ (PeerPicker *)peerPicker {
    return [[[self class]alloc]initWithTitle:nil message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
}

- (id)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ... {
    self = [super initWithTitle:nil message:kLongMessage delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
    if (self) {
        
        self.peers = [NSMutableArray array];
        self.ignoredPeerIDs = [NSMutableArray array];
        
        self.theImageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"bluetooth"]];
        [self addSubview:_theImageView];
        
        self.activityIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self addSubview:_activityIndicator];
        [_activityIndicator startAnimating];
        
        self.searchingLabel = [[UILabel alloc]init];
        _searchingLabel.textAlignment = UITextAlignmentLeft;
        _searchingLabel.textColor = [UIColor blackColor];
        _searchingLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:_searchingLabel];
        
        self.theTableView = [[UITableView alloc]initWithFrame:CGRectZero style:UITableViewStylePlain];
        _theTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _theTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _theTableView.backgroundColor = [UIColor clearColor];
        _theTableView.rowHeight = 44;
        _theTableView.dataSource = self;
        _theTableView.delegate = self;
        _theTableView.layer.borderColor = [UIColor lightGrayColor].CGColor;
        _theTableView.layer.borderWidth = 1.5;
        [self addSubview:_theTableView];
        
        self.session = [[GKSession alloc]initWithSessionID:@"swift_bluetooth" displayName:nil sessionMode:GKSessionModePeer];
        _session.delegate = self;
        _session.available = NO;
        
        [_ignoredPeerIDs addObject:_session.peerID];
        
        self.state = PeerPickerStateNormal;
    }
    return self;
}

- (void)show {
    [super show];
    _session.available = YES;
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    [_peers removeAllObjects];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    for (UIView *view in self.subviews) {
        if ([view isKindOfClass:[UILabel class]] && ![view isEqual:_searchingLabel]) {
			[view setHidden:YES];
		}
    }
    
    float width = self.frame.size.width;
    
    if (_state == PeerPickerStateNormal) {
        _searchingLabel.hidden = NO;
        _theImageView.hidden = NO;
        _theImageView.hidden = NO;
        _activityIndicator.hidden = NO;
        _theImageView.frame = CGRectMake((width/2)-30, 10, 30, 30);
        _searchingLabel.frame = CGRectMake((width/2)-40, 45, 120, 25);
        _activityIndicator.frame = CGRectMake((width/2)-70, 45, 25, 25);
        _theTableView.frame = CGRectMake(30, 75, width-90, self.frame.size.height-170);
        _searchingLabel.text = @"Searching...";
        self.message = kLongMessage;
    } else if (_state == PeerPickerStateConnecting) {
        _theImageView.hidden = YES;
        _theTableView.hidden = YES;
        _searchingLabel.text = @"Connecting...";
        _searchingLabel.frame = CGRectMake((width/2)-60, 10, 120, 25);
        _activityIndicator.frame = CGRectMake((width/2)-25, 50, 25, 25);
       // _activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _peers.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    PeerPickerCell *cell = (PeerPickerCell *)[_theTableView dequeueReusableCellWithIdentifier:kCellID];
    
    if (cell == nil) {
        cell = [[PeerPickerCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellID];
    }

    cell.isFirstCell = (indexPath.row == 0);
    cell.textLabel.text = [_session displayNameForPeer:[_peers objectAtIndex:indexPath.row]];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    [cell setNeedsDisplay];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_peerPickedBlock) {
        _peerPickedBlock([_peers objectAtIndex:indexPath.row]);
    }
    [_theTableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state {
    switch (state) {
        case GKPeerStateAvailable: {
            NSLog(@"Found Peer: %@",[_session displayNameForPeer:peerID]);
            if (![_peers containsObject:peerID] && ![_ignoredPeerIDs containsObject:peerID]) {
                [_peers addObject:peerID];
                [_theTableView reloadData];
            }
        } break;
        case GKPeerStateUnavailable: {
            [_peers removeObject:peerID];
        } break;
        default:
            break;
    }
}

- (void)session:(GKSession *)session didFailWithError:(NSError *)error {
    [TransparentAlert showAlertWithTitle:@"Bluetooth Error" andMessage:error.localizedDescription];
}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID {
    [[[TransparentAlert alloc]initWithTitle:@"Connect?" message:[NSString stringWithFormat:@"Would you like to connect to %@",[_session displayNameForPeer:peerID]] completionBlock:^(NSUInteger buttonIndex, UIAlertView *alertView) {
        if (buttonIndex == 1) {
            [_session acceptConnectionFromPeer:peerID error:nil];
        } else {
            [_session denyConnectionFromPeer:peerID];
        }
    } cancelButtonTitle:@"No" otherButtonTitles:@"YES", nil]show];
}

@end
