//
//  BTSender.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 2/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BTSender.h"

@implementation BTSender

@synthesize sessionController = _sessionController;

// BT SENDER METHODS

+ (id)sharedInstance {
    return [[[self alloc]init]autorelease];
}

- (void)createSessionMe:(GKSession *)session {
    self.sessionController = [BKSessionController sessionControllerWithSession:session];
    _sessionController.delegate = self;
}

- (void)sendBluetoothDataZ {
    NSString *filePath = [[NSUserDefaults standardUserDefaults]objectForKey:@"cellNameFileKey"];
    NSData *file = [NSData dataWithContentsOfFile:filePath];
    NSString *fileName = [filePath lastPathComponent];
    NSArray *array = [NSArray arrayWithObjects:fileName, file, nil];
    NSData *finalData = [NSKeyedArchiver archivedDataWithRootObject:array];
    [_sessionController sendDataToAllPeers:finalData];
    file = nil;
    array = nil;
    finalData = nil;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self sendBluetoothDataZ];
    }
}

- (void)peerPickerController:(GKPeerPickerController *)picker didConnectPeer:(NSString *)peerID toSession:(GKSession *)session {
    
    [self createSessionMe:session];
    
    picker.delegate = nil;
    [picker dismiss];
    [picker autorelease];
    
    UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"Connected" message:@"Would you like to send the file?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Send file", nil];
    [av show];
    [av release];
}

- (void)peerPickerControllerDidCancel:(GKPeerPickerController *)picker {
	picker.delegate = nil;
    [picker autorelease];
    self.sessionController.session.delegate = nil;
    self.sessionController.session = nil;
    self.sessionController = nil;
    downloaderAppDelegate *appDelegate = (downloaderAppDelegate *)[[UIApplication sharedApplication]delegate];
    [appDelegate makeSessionAvailable];
}

- (void)sessionControllerSenderDidFinishSendingData:(NSNotification *)aNotification {
    [self.sessionController.session disconnectFromAllPeers];
    self.sessionController.session.delegate = nil;
    self.sessionController.session = nil;
    self.sessionController = nil;
    downloaderAppDelegate *appDelegate = (downloaderAppDelegate *)[[UIApplication sharedApplication]delegate];
    [appDelegate makeSessionAvailable];
}

- (void)showAlert {
    downloaderAppDelegate *appDelegate = (downloaderAppDelegate *)[[UIApplication sharedApplication]delegate];
    [appDelegate makeSessionUnavailable];
    
    GKPeerPickerController *peerPicker = [[GKPeerPickerController alloc] init];
    peerPicker.delegate = self;
    peerPicker.connectionTypesMask = GKPeerPickerConnectionTypeNearby;
    [peerPicker show]; 
    
}

@end
