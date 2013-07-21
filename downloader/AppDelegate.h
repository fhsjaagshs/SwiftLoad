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
#define fileSize(file) (float)[[[NSFileManager defaultManager]attributesOfItemAtPath:file error:nil]fileSize]
#define fileDate(file) [[[NSFileManager defaultManager]attributesOfFileSystemForPath:file error:nil]fileCreationDate]
#define NSUserDefaultsOFK(key) [[NSUserDefaults standardUserDefaults]objectForKey:key]
#define NSUserDefaultsOFKKill(key) [[NSUserDefaults standardUserDefaults]removeObjectForKey:key]
#define KILL_TIMER(q) if (q) {[q invalidate]; q=nil;}
#define myCyan [UIColor colorWithRed:46.0f/255.0f green:1.0f blue:1.0f alpha:1.0f]
#define bgcolor [UIColor colorWithWhite:9.0f/10.0f alpha:1.0f]

extern NSString * const NSFileName;

void fireNotification(NSString *filename);
NSString * getResource(NSString *raw);
float sanitizeMesurement(float measurement);
NSString * getNonConflictingFilePathForPath(NSString *path);
void audioRouteChangeListenerCallback(void *inUserData, AudioSessionPropertyID inPropertyID, UInt32 inPropertyValueSize, const void *inPropertyValue);

@interface AppDelegate : UIResponder <UIApplicationDelegate, GKSessionDelegate, DBSessionDelegate, DBRestClientDelegate, MBProgressHUDDelegate, GKPeerPickerControllerDelegate, AVAudioPlayerDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) MyFilesViewController *viewController;

// Audio Player
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
- (void)skipToPreviousTrack;
- (void)skipToNextTrack;
- (void)togglePlayPause;
- (void)showArtworkForFile:(NSString *)file;
- (void)showMetadataInLockscreenWithArtist:(NSString *)artist title:(NSString *)title album:(NSString *)album;

// File tracking
@property (nonatomic, strong) NSString *openFile;
@property (nonatomic, strong) NSString *managerCurrentDir;

// Printing
- (void)printFile:(NSString *)file fromView:(UIView *)view;

// Emailing
- (void)sendFileInEmail:(NSString *)file fromViewController:(UIViewController *)vc;
- (void)sendStringAsSMS:(NSString *)string fromViewController:(UIViewController *)vc;

// Audio Player
@property (nonatomic, strong) NSString *nowPlayingFile;

// Bluetooth File Transmission
- (void)prepareFileForBTSending:(NSString *)file;

// Dropbox Uploading
- (void)uploadLocalFile:(NSString *)localPath;

// Downloading
- (void)downloadFileUsingSFTP:(NSURL *)url withUsername:(NSString *)username andPassword:(NSString *)password;
- (void)downloadFile:(NSString *)stouPrelim;

// HUD management
- (void)setVisibleHudCustomView:(UIView *)view;
- (void)setSecondaryTitleOfVisibleHUD:(NSString *)newTitle;
- (void)setVisibleHudMode:(MBProgressHUDMode)mode;
- (void)setProgressOfVisibleHUD:(float)progress;
- (void)showHUDWithTitle:(NSString *)title;
- (void)hideHUD;
- (void)setTitleOfVisibleHUD:(NSString *)newTitle;
- (void)showSelfHidingHudWithTitle:(NSString *)title;
- (void)hideVisibleHudAfterDelay:(float)delay;
- (MBProgressHUD *)getVisibleHUD;
- (int)getTagOfVisibleHUD;
- (void)setTagOfVisibleHUD:(int)tag;

// Downloading-specific HUDs
//- (void)showFailedAlertForFilename:(NSString *)fileName;
//- (void)showFinishedAlertForFilename:(NSString *)fileName;

@end
