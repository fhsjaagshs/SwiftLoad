//
//  downloaderAppDelegate.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 8/11/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kAppDelegate (AppDelegate *)[[UIApplication sharedApplication]delegate]
#define kDocsDir [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#define kLibDir [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#define kCachesDir [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#define fileDate(file) [[[NSFileManager defaultManager]attributesOfItemAtPath:file error:nil]fileModificationDate]
#define NSUserDefaultsOFK(key) [[NSUserDefaults standardUserDefaults]objectForKey:key]
#define NSUserDefaultsOFKKill(key) [[NSUserDefaults standardUserDefaults]removeObjectForKey:key]
#define KILL_TIMER(q) if (q) {[q invalidate]; q=nil;}

extern NSString * const NSFileName;
extern NSString * const kCopyListChangedNotification;

float systemVersion(void);

BOOL isDirectory(NSString *filePath);
float fileSize(NSString *filePath);

void fireFinishDLNotification(NSString *filename);
NSString * getResource(NSString *raw);
float sanitizeMesurement(float measurement);
NSString * getNonConflictingFilePathForPath(NSString *path);
void audioRouteChangeListenerCallback(void *inUserData, AudioSessionPropertyID inPropertyID, UInt32 inPropertyValueSize, const void *inPropertyValue);

@interface AppDelegate : UIResponder <UIApplicationDelegate, GKSessionDelegate, DBSessionDelegate, DBRestClientDelegate, GKPeerPickerControllerDelegate, AVAudioPlayerDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) MyFilesViewController *viewController;

// Audio Player
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) NSString *nowPlayingFile;
- (void)playFile:(NSString *)file;
- (void)skipToPreviousTrack;
- (void)skipToNextTrack;
- (void)togglePlayPause;

// File tracking
@property (nonatomic, strong) NSString *openFile;
@property (nonatomic, strong) NSString *managerCurrentDir;

// Printing
- (void)printFile:(NSString *)file fromView:(UIView *)view;

// Emailing
- (void)sendFileInEmail:(NSString *)file;

// Downloading
- (void)downloadFile:(NSString *)stouPrelim;

@end
