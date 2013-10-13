//
//  downloaderAppDelegate.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 8/11/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kAppDelegate ((AppDelegate *)[[UIApplication sharedApplication]delegate])
#define kDocsDir [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#define kLibDir [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#define kCachesDir [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#define fileDate(file) [[[NSFileManager defaultManager]attributesOfItemAtPath:file error:nil]fileModificationDate]

extern NSString * const NSFileName;
extern NSString * const kCopyListChangedNotification;

extern NSString * const kActionButtonNameEmail;
extern NSString * const kActionButtonNameP2P;
extern NSString * const kActionButtonNameDBUpload;
extern NSString * const kActionButtonNamePrint;
extern NSString * const kActionButtonNameSavePhotoLibrary;
extern NSString * const kActionButtonNameEditID3;

BOOL isDirectory(NSString *filePath);
float fileSize(NSString *filePath);

void fireFinishDLNotification(NSString *filename);
NSString * getNonConflictingFilePathForPath(NSString *path);

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;

// Audio Player
@property (nonatomic, strong) PPAudioPlayer *audioPlayer;
@property (nonatomic, strong) NSString *nowPlayingFile;
- (void)playFile:(NSString *)file;
- (void)skipToPreviousTrack;
- (void)skipToNextTrack;
- (void)togglePlayPause;

// File tracking
@property (nonatomic, strong) NSString *managerCurrentDir;

// Printing, emailing, downloading
- (void)printFile:(NSString *)file;
- (void)sendFileInEmail:(NSString *)file;
- (void)downloadFile:(NSString *)stouPrelim;

@end
