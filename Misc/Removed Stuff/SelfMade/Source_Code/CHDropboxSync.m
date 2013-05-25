//
//  CHDropboxSync.m
//
//  Created by Chris Hulbert on 11/12/11.
//  Copyright (c) 2011 Splinter Software. All rights reserved.
//
//  MIT license: No warranties!
//  If you plan on using this code in one of your own projects, test it well!
//  For instance, what happens if the network connection fails half way through a sync, and then you re-sync later - anything get lost? My testing says this is fine, but it's your responsibility to test it thoroughly in your particular app.

#import "CHDropboxSync.h"
#import "ConciseKit.h"
#import <DropboxSDK/DropboxSDK.h>
#import "Reachability.h"
#import "SyncTask.h"
#import <QuartzCore/QuartzCore.h>
#import "CustomAlertView.h"

#define defaultsFiles   @"CHDropboxSyncFiles"
#define defaultsFolders @"CHDropboxSyncFolders"

// Privates
@interface CHDropboxSync() {
    UILabel *workingLabel;
}
@property(retain) DBRestClient* client;
@property(retain) NSMutableSet* remoteFoldersPendingMetadata;
@property(retain) NSMutableDictionary* remoteFiles;
@property(retain) NSMutableDictionary* remoteFolders;
@property(retain) NSMutableDictionary* remoteFileRevs;
@property(retain) NSMutableDictionary* remoteFileDates;
@property(retain) NSDictionary* localFiles;
@property(retain) NSDictionary* localFolders;
@property(retain) NSDictionary* lastSyncFiles;
@property(retain) NSDictionary* lastSyncFolders;
@property(retain) NSMutableArray* todo;
@property(retain) SyncTask* lastTask;
@property(retain) NSString* lastAlertMessage;
- (void)remoteMetadataComplete;
- (void)doTodoItem;
- (void)doSyncPostConfirmation;
- (void)savePostSyncStatus;
@end

@implementation CHDropboxSync

@synthesize client;
@synthesize remoteFoldersPendingMetadata;
@synthesize remoteFiles;
@synthesize remoteFolders;
@synthesize remoteFileRevs;
@synthesize remoteFileDates;
@synthesize localFiles;
@synthesize localFolders;
@synthesize lastSyncFiles;
@synthesize lastSyncFolders;
@synthesize todo;
@synthesize delegate;
@synthesize lastTask;
@synthesize lastAlertMessage;

- (void)dealloc {
    self.client = nil;
    self.remoteFoldersPendingMetadata = nil;
    self.remoteFiles = nil;
    self.remoteFolders = nil;
    self.remoteFileRevs = nil;
    self.remoteFileDates = nil;
    self.localFiles = nil;
    self.localFolders = nil;
    self.lastSyncFiles = nil;
    self.lastSyncFolders = nil;
    self.todo = nil;
    self.delegate = nil;
    self.lastTask = nil;
    self.lastAlertMessage = nil;
    [super dealloc];
}

#pragma mark - Alert/progress view

- (void)showWorking {
    if (workingLabel) {
        return; // Already visible
    }
    
    UIWindow* w = [[[UIApplication sharedApplication]delegate]window];
    workingLabel = [[UILabel alloc]init];
    workingLabel.textAlignment = UITextAlignmentRight;
    workingLabel.text = @"Syncing... ";
    workingLabel.textColor = [UIColor whiteColor];
    int ht = 30;
    workingLabel.frame = CGRectMake(-120, 431-ht, 120, ht);
    workingLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    workingLabel.layer.cornerRadius = 10;
    
    // Spinner
    UIActivityIndicatorView *s = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    int gap = (workingLabel.frame.size.height - s.frame.size.height) / 2;
    s.frame = CGRectOffset(s.frame, 10+gap, gap);
    [s startAnimating];
    [workingLabel addSubview:s];
    [s release];
    
    // Swoosh it in
    [w addSubview:workingLabel];
    [UIView animateWithDuration:0.3 animations:^{
        workingLabel.frame = CGRectOffset(workingLabel.frame, 110, 0);
    }];
}

- (void)hideWorking {
    if (!workingLabel) {
        return; // Already hidden
    }
    [UIView animateWithDuration:0.3 animations:^{
        workingLabel.frame = CGRectMake(-workingLabel.frame.size.width, workingLabel.frame.origin.y, workingLabel.frame.size.width, workingLabel.frame.size.height);
    } completion:^(BOOL finished) {
        [workingLabel removeFromSuperview];
        [workingLabel release];
        workingLabel = nil;
    }];
}

- (void)alertMessage:(NSString*)msg {
    workingLabel.text = msg;
    self.lastAlertMessage = msg;
}

- (void)alertCompleteWithMessage:(NSString*)message {
    [self alertMessage:message];
    [self performSelector:@selector(hideWorking) withObject:nil afterDelay:0.5];
}

#pragma mark - Completion

// Tell the delegate about completion
- (void)tellDelegateComplete {
    [self savePostSyncStatus];
    if ([delegate respondsToSelector:@selector(syncComplete)]) {
        // Do it after a short delay so the caller (dbrestclient) gets a chance to finish what it's doing before we zombify it!
        [delegate performSelector:@selector(syncComplete) withObject:nil afterDelay:0.001];
    }
}

- (void)successWithMessage:(NSString*)message {
    [self savePostSyncStatus];
    [self alertCompleteWithMessage:message];
    
    [self tellDelegateComplete];
}
- (void)success {
    [self successWithMessage:@"Success   "];
}
- (void)successNothingToDo {
    [self successWithMessage:@"Success   "];
}

- (void)failure:(NSString*)message {
    if (message) {
        [self successWithMessage:@"Failure"];
        CustomAlertView *cav = [[CustomAlertView alloc]initWithTitle:@"Failure Syncing" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [cav show];
        [cav release];
    }
    [self savePostSyncStatus];
    [self performSelector:@selector(hideWorking) withObject:nil afterDelay:0.5];
    [self tellDelegateComplete];
}

- (void)cancel {
    [self failure:nil];
}

#pragma mark - Local file/folder listings

// Get the current status of files and folders
- (void)getLocalStatusForFiles:(NSDictionary**)_files andFolders:(NSDictionary**)_folders {
    NSMutableDictionary* files = [NSMutableDictionary dictionary];
    NSMutableDictionary* folders = [NSMutableDictionary dictionary];
    
    // NSFileManager's enumeratorAtURL crashes! Don't use it
    NSString* root = $.documentPath;
    NSMutableSet* pathsToSearch = $mset(root);
    while (pathsToSearch.count) {
        // Pop a path to search
        NSString* pathToSearch = [pathsToSearch anyObject];
        [pathsToSearch removeObject:pathToSearch];
        
        // Scan it
        NSArray* contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:pathToSearch error:nil];
        for (NSString* item in contents) {
            // Skip hidden/system files - you may want to change this if your files start with ., however dropbox errors on many 'ignored' files such as .DS_Store which you'll want to skip
            if ([item hasPrefix:@"."]) continue;
            
            // Item is a file or a folder
            NSString* itemPath = [pathToSearch stringByAppendingPathComponent:item]; // Get the full path for it
            
            // Get the attributes
            NSDictionary* attribs = [[NSFileManager defaultManager] attributesOfItemAtPath:itemPath error:nil];
            BOOL isDirectory = $eql([attribs $for:NSFileType], NSFileTypeDirectory);
            BOOL isFile = $eql([attribs $for:NSFileType], NSFileTypeRegular);
            NSDate* modified = [attribs $for:NSFileModificationDate];
            
            // Recurse if its a folder
            if (isDirectory) {
                [pathsToSearch addObject:itemPath];
            }
            
            // Do something with it
            NSString* itemWithoutRoot = [itemPath substringFromIndex:root.length];
            if (isFile) {
                [files setObject:modified forKey:itemWithoutRoot];
            }
            if (isDirectory) {
                [folders setObject:modified forKey:itemWithoutRoot];
            }
        }
    }
    
    *_files = [NSDictionary dictionaryWithDictionary:files];
    *_folders = [NSDictionary dictionaryWithDictionary:folders];
}

// Call this after you've synced - store the current status of all files, so that next time you'll know what to delete
- (void)savePostSyncStatus {
    NSDictionary* files;
    NSDictionary* folders;
    [self getLocalStatusForFiles:&files andFolders:&folders];
    
    // Store it in the user defaults
    [[NSUserDefaults standardUserDefaults] setObject:files forKey:defaultsFiles];
    [[NSUserDefaults standardUserDefaults] setObject:folders forKey:defaultsFolders];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Getting the remote folder/files

// Get the list of files/folders and their modified dates from the server
- (void)startGettingRemoteMetadata {
    self.remoteFiles = [NSMutableDictionary dictionary];
    self.remoteFileRevs = [NSMutableDictionary dictionary];
    self.remoteFileDates = [NSMutableDictionary dictionary];
    self.remoteFolders = [NSMutableDictionary dictionary];
    self.remoteFoldersPendingMetadata = $mset(@"/");
    [client loadMetadata:@"/"];
}

// Called by dropbox when the metadata for a folder has returned
- (void)restClient:(DBRestClient*)_client loadedMetadata:(DBMetadata*)metadata {
    for (DBMetadata* item in metadata.contents) {
        if (item.isDirectory) {
            [remoteFolders setObject:item.lastModifiedDate forKey:item.path];
            [remoteFoldersPendingMetadata addObject:item.path];
            [client loadMetadata:item.path];
        } else {
            [remoteFiles setObject:item.lastModifiedDate forKey:item.path];
            [remoteFileRevs setObject:item.rev forKey:item.path];
            [remoteFileDates setObject:item.lastModifiedDate forKey:item.path];
        }
    }
    
    // Note that this folder's data has arrived
    [remoteFoldersPendingMetadata removeObject:metadata.path];

    // Is this the last one, no more recursing needed?
    if (!remoteFoldersPendingMetadata.count) {
        [self remoteMetadataComplete];
    }
}

// Called by dropbox upon failure
- (void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError*)error {
    [self failure:@"Couldn't get file list from Dropbox"];
}

#pragma mark - Building the todo-list using a sync strategy

// Makes a todo list for the necessary folder sync operations
- (void)syncFoldersMakeAddTodo:(NSMutableArray*)todoAdd deleteTodo:(NSMutableArray*)todoDelete {
    NSMutableSet* all = [NSMutableSet set];
    [all addObjectsFromArray:localFolders.allKeys];
    [all addObjectsFromArray:remoteFolders.allKeys];
    
    for (NSString* folder in all) {
        BOOL isLocal = [localFolders objectForKey:folder] != nil;
        BOOL isRemote = [remoteFolders objectForKey:folder] != nil;
        BOOL isLastSync = [lastSyncFolders objectForKey:folder] != nil;
        
        if (isLocal && !isRemote) {
            // We have it, dropbox doesn't
            
            // Start off with: we were last synced fine, then all 3 used to be true
            
            // If was deleted from dropbox, then we sync
            // Then isLastSync would be true, isRemote false
            // And we'd need to delete locally
            
            // If we added it since last sync
            // Then isLastSync would be false
            // And we'd need to add it remotely
            
            // If this is the first sync, then isLastSync would be false
            // And we'd need to add it remotely
            
            if (isLastSync) {
                // Delete locally
                [todoDelete addObject:[SyncTask syncTaskWithType:SyncTaskTypeFolderLocalDelete andPath:folder]];
            } else {
                // Add remotely
                [todoAdd addObject:[SyncTask syncTaskWithType:SyncTaskTypeFolderRemoteAdd andPath:folder]];
            }
        }
        if (isRemote && !isLocal) {
            // We don't have it, dropbox does
            
            // If was removed locally since last sync
            // then isLastSync=true
            // and we'd need to remove it remotely
            
            // If was added to dropbox since last sync
            // then isLastSync=false
            // and we'd need to add it locally
            
            // If never synced, islastsync=false, add locally, which is good
            
            if (isLastSync) {
                // Remove it remotely
                [todoDelete addObject:[SyncTask syncTaskWithType:SyncTaskTypeFolderRemoteDelete andPath:folder]];
            } else {
                // Add locally
                [todoAdd addObject:[SyncTask syncTaskWithType:SyncTaskTypeFolderLocalAdd andPath:folder]];
            }
        }
    }
}

// Makes the todo list for file operations
- (void)syncFilesTodo {
    NSMutableSet* all = [NSMutableSet set];
    [all addObjectsFromArray:localFiles.allKeys];
    [all addObjectsFromArray:remoteFiles.allKeys];
    
    for (NSString* file in all) {
        NSDate* local = [localFiles objectForKey:file];
        NSDate* remote = [remoteFiles objectForKey:file];
        NSDate* lastSync = [lastSyncFiles objectForKey:file];
        if (local && remote) {
            // File is in both places, but are the dates the same?
            double delta = local.timeIntervalSinceReferenceDate - remote.timeIntervalSinceReferenceDate;
            BOOL same = ABS(delta)<2; // If they're within 2 seconds, that'll do
            if (!same) {
                // Dates are different, so we need to do something
                // If this was the proper algorithm, we'd check to see if both had changed since the last sync
                // And if so, keep both and rename the older one '*_conflicted'
                if (local.timeIntervalSinceReferenceDate > remote.timeIntervalSinceReferenceDate) {
                    // Local is newer
                    // So send the local file to dropbox
                    [todo addObject:[SyncTask syncTaskWithType:SyncTaskTypeFileUpload andPath:file]];
                } else {
                    // Remote is newer
                    // So download the file
                    [todo addObject:[SyncTask syncTaskWithType:SyncTaskTypeFileDownload andPath:file]];
                }
            }
        } else { // Not in both places
            // Say at the end of last sync, it would be in all 3 places: local, remote, and sync
            if (remote && !local) {
                // Dropbox has it, we don't
                // If it was added to db since last sync, it won't be in our sync list, so add it local
                // If it was removed locally since last sync, it'll be in our sync list, so remove from db
                // If never been synced, it won't be in our sync list, so add it locally
                if (lastSync) {
                    // Remove from db
                    [todo addObject:[SyncTask syncTaskWithType:SyncTaskTypeFileRemoteDelete andPath:file]];
                } else {
                    // Download it
                    [todo addObject:[SyncTask syncTaskWithType:SyncTaskTypeFileDownload andPath:file]];
                }
            }
            if (local && !remote) {
                // We have it, dropbox doesn't
                // If it was added locally since last sync, it won't be in our sync list, so upload it
                // If it was deleted from db since last sync, it will be in our sync list, so delete it locally
                // If never synced, it won't be in our sync list, so upload it
                if (lastSync) {
                    // Delete locally
                    [todo addObject:[SyncTask syncTaskWithType:SyncTaskTypeFileLocalDelete andPath:file]];
                } else {
                    // Upload it
                    [todo addObject:[SyncTask syncTaskWithType:SyncTaskTypeFileUpload andPath:file]];
                }
            }
        }
    }
}

#pragma mark - Main flow of control

// Note that whomever calls this must retain this instance until it's finished
- (void)doSync {
    if (![[DBSession sharedSession]isLinked]) {
        [self failure:@"Failed"];
        CustomAlertView *cav = [[CustomAlertView alloc]initWithTitle:@"Not Linked" message:@"You did not link this device to Dropbox. You need to click the link button." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [cav show];
        [cav release];
        return;
    }

    BOOL wifi = [[Reachability reachabilityForLocalWiFi] isReachableViaWiFi];

    if (!wifi) {
        CustomAlertView *cav = [[CustomAlertView alloc]initWithTitle:@"Sync over 3G?" message:@"Are you sure? Using data is both slow and expensive." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Sync", nil];
        [cav show];
        [cav release];
    } else {
        [self doSyncPostConfirmation];
    }

}

// Called when they confirm
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.firstOtherButtonIndex) {
        [self doSyncPostConfirmation];
    } else {
        [self cancel];
    }
}

// Actually get started on the sync
- (void)doSyncPostConfirmation {    
    [self showWorking];
        
    self.client = [[[DBRestClient alloc] initWithSession:[DBSession sharedSession]] autorelease];
    self.client.delegate = self;
    
    // Get the current status of local and dropbox, and the status at the end of the last sync
    NSDictionary* files;
    NSDictionary* folders;
    [self getLocalStatusForFiles:&files andFolders:&folders];
    self.localFiles = files;
    self.localFolders = folders;
    
    self.lastSyncFiles = [[NSUserDefaults standardUserDefaults] dictionaryForKey:defaultsFiles];
    self.lastSyncFolders = [[NSUserDefaults standardUserDefaults] dictionaryForKey:defaultsFolders];

    // Get the current status of dropbox
    [self startGettingRemoteMetadata];
    // Once that finishes, we continue at 'remoteMetadataComplete'
}

// Called when the current status metadata is gotten from dropbox
- (void)remoteMetadataComplete {
    
    // Now we get down to figuring out what needs to be done
    // Strategy is: compare local vs dropbox, if there's a difference, use the last sync to hint what happened
    
    // Make the todo-list for sync operations. Folders adds first, then file ops, then folder deletions last
    self.todo = [NSMutableArray array];
    NSMutableArray* folderDeleteTodo = [NSMutableArray array];
    [self syncFoldersMakeAddTodo:self.todo deleteTodo:folderDeleteTodo];
    [self syncFilesTodo];
    [self.todo addObjectsFromArray:folderDeleteTodo];
    
    // Now perform the todo-list
    if (self.todo.count) {
        [self doTodoItem];
    } else {
        [self successNothingToDo];
    }
}

#pragma mark - Working through the todo list

// Do the next item on the todo list
- (void)doTodoItem {
    // All done?
    if (!todo.count) {
        [self success];
        return;
    }
    
    // Pop the first item
    SyncTask* task = [todo objectAtIndex:0];
    [[task retain] autorelease];
    [todo removeObjectAtIndex:0];
    self.lastTask = task; // So that the async callbacks will know which task we're working on
    
    // Expand its path
    NSString* localPath = [[$ documentPath] stringByAppendingPathComponent:task.path];
    NSError* err = nil;
    
    // Do it!
    // File tasks
    if (task.taskType == SyncTaskTypeFileDownload) {
        [client loadFile:task.path intoPath:localPath];
    }
    if (task.taskType == SyncTaskTypeFileUpload) {
        // parentrev nil only works if we're uploading a new file that doesn't exist remotely. If we're uploading a newer version over an older one, we need the older one's rev
        [client uploadFile:localPath.lastPathComponent toPath:task.path.stringByDeletingLastPathComponent withParentRev:[remoteFileRevs objectForKey:task.path] fromPath:localPath];
    }
    if (task.taskType == SyncTaskTypeFileRemoteDelete) {
        [client deletePath:task.path];
    }
    if (task.taskType == SyncTaskTypeFileLocalDelete) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:localPath error:&err];
        }
        if (err) {
            [self failure:$str(@"Error deleting local file %@: %@", task.path, err)];
        } else {
            [self performSelector:@selector(doTodoItem) withObject:nil afterDelay:0.001]; // Then do the next item on the todo list
        }
    }
    // Folder tasks
    if (task.taskType == SyncTaskTypeFolderLocalAdd) {
        [[NSFileManager defaultManager] createDirectoryAtPath:localPath withIntermediateDirectories:YES attributes:nil error:&err];
        if (err) {
            [self failure:$str(@"Error creating local folder %@: %@", task.path, err)];
        } else {
            [self performSelector:@selector(doTodoItem) withObject:nil afterDelay:0.001]; // Then do the next item on the todo list
        }
    }
    if (task.taskType == SyncTaskTypeFolderLocalDelete) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:localPath error:&err];
        }
        if (err) {
            [self failure:$str(@"Error deleting local folder %@: %@", task.path, err)];
        } else {
            [self performSelector:@selector(doTodoItem) withObject:nil afterDelay:0.001]; // Then do the next item on the todo list
        }
    }
    if (task.taskType == SyncTaskTypeFolderRemoteAdd) {
        [client createFolder:task.path];
    }
    if (task.taskType == SyncTaskTypeFolderRemoteDelete) {
        [client deletePath:task.path];
    }
}

#pragma mark - DBRestClient's callbacks for the todo items

- (void)restClient:(DBRestClient *)client createdFolder:(DBMetadata *)folder {
    [self performSelector:@selector(doTodoItem) withObject:nil afterDelay:0.001]; // Then do the next item on the todo list
}
- (void)restClient:(DBRestClient *)client createFolderFailedWithError:(NSError *)error {
    [self failure:$str(@"Error creating dropbox folder: %@", error)];
}
     
         
- (void)restClient:(DBRestClient *)client deletedPath:(NSString *)path {
    [self performSelector:@selector(doTodoItem) withObject:nil afterDelay:0.001]; // Then do the next item on the todo list
}
- (void)restClient:(DBRestClient *)client deletePathFailedWithError:(NSError *)error {
    [self failure:$str(@"Error deleting dropbox file/folder: %@", error)];
}

         
- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath metadata:(DBMetadata *)metadata {
    // Now the file has uploaded, we need to set its 'last modified' date locally to match the date on dropbox.
    // Unfortunately we can't change the dropbox date to match the local date, which would be more appropriate, really.
    NSDictionary* attr = $dict(metadata.lastModifiedDate, NSFileModificationDate);
    NSError* err = nil;
    [[NSFileManager defaultManager] setAttributes:attr ofItemAtPath:srcPath error:&err];
    
    if (err) {
        [self failure:$str(@"Error setting modified date: %@", err)];
    } else {
        [self performSelector:@selector(doTodoItem) withObject:nil afterDelay:0.001]; // Then do the next item on the todo list
    }
}
- (void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error {
    [self failure:$str(@"Error uploading to dropbox: %@", error)];
}
         
- (void)restClient:(DBRestClient *)client loadedFile:(NSString *)destPath {
    // Now the file has downloaded, we need to set its 'last modified' date locally to match the date on dropbox
    NSDate* lastModified = [remoteFileDates $for:lastTask.path];
    NSDictionary* attr = $dict(lastModified, NSFileModificationDate);
    NSError* err = nil;
    [[NSFileManager defaultManager] setAttributes:attr ofItemAtPath:destPath error:&err];
    
    if (err) {
        [self failure:$str(@"Error setting modified date: %@", err)];
    } else {
        [self performSelector:@selector(doTodoItem) withObject:nil afterDelay:0.001]; // Then do the next item on the todo list
    }
}
- (void)restClient:(DBRestClient *)client loadFileFailedWithError:(NSError *)error {
    [self failure:$str(@"Error downloading from dropbox: %@", error)];
}

@end
