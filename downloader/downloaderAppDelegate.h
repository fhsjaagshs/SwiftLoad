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
#define fileSize(file) (float)[[[NSFileManager defaultManager]attributesOfItemAtPath:file error:nil]fileSize]
#define KILL_TIMER(q) if (q) {[q invalidate]; q=nil;}
#define myCyan [UIColor colorWithRed:46.0f/255.0f green:1.0f blue:1.0f alpha:1.0f]

float sanitizeMesurement(float measurement);
NSString * getNonConflictingFilePathForPath(NSString *path);

@interface downloaderAppDelegate : UIResponder <UIApplicationDelegate, BKSessionControllerDelegate, GKSessionDelegate, DBSessionDelegate, DBRestClientDelegate, MBProgressHUDDelegate, GKPeerPickerControllerDelegate, UITextFieldDelegate, NSURLConnectionDelegate, MFMailComposeViewControllerDelegate> {
    CustomAlertView *avL;
    UITextField *serverField;
    UITextField *usernameField;
    UITextField *passwordField;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) downloaderViewController *viewController;


@property (nonatomic, retain) DBRestClient *restClient;

// Downloading
@property (nonatomic, retain) NSMutableData *downloadedData;
@property (nonatomic, assign) float expectedDownloadingFileSize;
@property (nonatomic, retain) NSString *downloadingFileName;
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskIdentifier;
@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, assign) float downloadedBytes;

// File tracking
@property (nonatomic, retain) NSString *openFile;
@property (nonatomic, retain) NSString *managerCurrentDir;

// Printing
- (void)printFile:(NSString *)file fromView:(UIView *)view;

// Emailing
- (void)sendFileInEmail:(NSString *)file fromViewController:(UIViewController *)vc;

// Audio Player
@property (nonatomic, retain) NSString *nowPlayingFile;

// Bluetooth File Transmission
@property (nonatomic, retain) BKSessionController *sessionController;
@property (nonatomic, retain) BKSessionController *sessionControllerSending;
@property (nonatomic, retain) UIProgressView *progressView;
@property (nonatomic, assign) BOOL isReciever;

- (void)killSession;
- (void)startSession;
- (void)makeSessionUnavailable;
- (void)makeSessionAvailable;
- (void)showBTController;

// Dropbox Uploading
- (void)uploadLocalFile:(NSString *)localPath;

// FTP Upload
- (void)showFTPUploadController;

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
- (void)showFailedAlertForFilename:(NSString *)fileName;
- (void)showFinishedAlertForFilename:(NSString *)fileName;

// Downloading
- (void)downloadURL:(NSURL *)url;
- (void)downloadFromAppDelegate:(NSString *)stouPrelim;

@end
