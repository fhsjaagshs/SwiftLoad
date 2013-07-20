//
//  downloaderAppDelegate.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 8/11/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kAppDelegate (downloaderAppDelegate *)[[UIApplication sharedApplication]delegate]
#define mainVC (downloaderViewController *)[(downloaderAppDelegate *)[[UIApplication sharedApplication]delegate]viewController]
#define kDocsDir [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#define kLibDir [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#define kCachesDir [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#define fileSize(file) (float)[[[NSFileManager defaultManager]attributesOfItemAtPath:file error:nil]fileSize]
#define fileDate(file) [[[NSFileManager defaultManager]attributesOfFileSystemForPath:file error:nil]fileCreationDate]
#define NSUserDefaultsOFK(key) [[NSUserDefaults standardUserDefaults]objectForKey:key]
#define NSUserDefaultsOFKKill(key) [[NSUserDefaults standardUserDefaults]removeObjectForKey:key]
#define KILL_TIMER(q) if (q) {[q invalidate]; q=nil;}
#define myCyan [UIColor colorWithRed:46.0f/255.0f green:1.0f blue:1.0f alpha:1.0f]

void fireNotification(NSString *filename);
NSString * getResource(NSString *raw);
float sanitizeMesurement(float measurement);
NSString * getNonConflictingFilePathForPath(NSString *path);
void audioRouteChangeListenerCallback(void *inUserData, AudioSessionPropertyID inPropertyID, UInt32 inPropertyValueSize, const void *inPropertyValue);

@interface downloaderAppDelegate : UIResponder <UIApplicationDelegate, GKSessionDelegate, DBSessionDelegate, DBRestClientDelegate, MBProgressHUDDelegate, GKPeerPickerControllerDelegate, AVAudioPlayerDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) MyFilesViewController *viewController;

//@property (nonatomic, retain) DBRestClient *restClient;

// ActionSheets
@property (nonatomic, assign) BOOL uiasVis;

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

/*@property (nonatomic, strong) BKSessionController *sessionController;
@property (nonatomic, strong) BKSessionController *sessionControllerSending;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, assign) BOOL isReciever;*/

/*- (void)killSession;
- (void)startSession;
- (void)makeSessionUnavailable;
- (void)makeSessionAvailable;
- (void)showBTController;*/

// Dropbox Uploading
- (void)uploadLocalFile:(NSString *)localPath;

// FTP
//- (void)showFTPUploadController;
- (void)downloadFileUsingFTP:(NSString *)url;
- (void)downloadFileUsingSFTP:(NSURL *)url withUsername:(NSString *)username andPassword:(NSString *)password;

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

// Downloading
- (void)downloadFromAppDelegate:(NSString *)stouPrelim;

@end
