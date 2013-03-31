//
//  UIView+Dropbox_Blocks.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 3/30/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "DroppinBadassBlocks.h"
#import <DropboxSDK/DBRestClient.h>
#import <objc/runtime.h>

@implementation DroppinBadassBlocks

+ (id)getInstance {
    DroppinBadassBlocks *restClient = [[DroppinBadassBlocks alloc]initWithSession:[DBSession sharedSession]];
    restClient.delegate = restClient;
    return restClient;
}

//
// Links
//

+ (void)loadSharableLinkForFile:(NSString *)path andCompletionBlock:(void(^)(NSString *link, NSString *path, NSError *error))block {
    objc_setAssociatedObject(kAppDelegate, "loadSharableLinkForFile:", [block copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [[DroppinBadassBlocks getInstance]loadSharableLinkForFile:path shortUrl:YES];
}

- (void)restClient:(DBRestClient *)restClient loadedSharableLink:(NSString *)link forFile:(NSString *)path {
    void(^block)(NSString *link, NSString *path, NSError *error) = objc_getAssociatedObject(kAppDelegate, "loadSharableLinkForFile:");
    block(link, path, nil);
    Block_release(block);
    objc_removeAssociatedObjects(kAppDelegate);
}

- (void)restClient:(DBRestClient *)restClient loadSharableLinkFailedWithError:(NSError *)error {
    void(^block)(NSString *link, NSString *path, NSError *error) = objc_getAssociatedObject(kAppDelegate, "loadSharableLinkForFile:");
    block(nil, nil, error);
    Block_release(block);
    objc_removeAssociatedObjects(kAppDelegate);
}

//
// File Downloading
//

+ (void)loadFile:(NSString *)path intoPath:(NSString *)destinationPath withCompletionBlock:(void(^)(DBMetadata *metadata, NSError *error))block andProgressBlock:(void(^)(CGFloat progress))progBlock {
    objc_setAssociatedObject(kAppDelegate, "loadFile:intoPath: main", [block copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(kAppDelegate, "loadFile:intoPath: progress", [progBlock copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [[DroppinBadassBlocks getInstance]loadFile:path intoPath:destinationPath];
}

- (void)restClient:(DBRestClient *)client loadedFile:(NSString *)destPath contentType:(NSString *)contentType metadata:(DBMetadata *)metadata {
    void(^block)(DBMetadata *metadata, NSError *error) = objc_getAssociatedObject(kAppDelegate, "loadFile:intoPath: main");
    block(metadata, nil);
    Block_release(block);
    objc_removeAssociatedObjects(kAppDelegate);
}

- (void)restClient:(DBRestClient *)client loadProgress:(CGFloat)progress forFile:(NSString *)destPath {
    void(^block)(CGFloat progress) = objc_getAssociatedObject(kAppDelegate, "loadFile:intoPath: progress");
    block(progress);
    Block_release(block);
    objc_removeAssociatedObjects(kAppDelegate);
}

- (void)restClient:(DBRestClient *)client loadFileFailedWithError:(NSError *)error {
    void(^block)(DBMetadata *metadata, NSError *error) = objc_getAssociatedObject(kAppDelegate, "loadFile:intoPath: main");
    block(nil, error);
    Block_release(block);
    objc_removeAssociatedObjects(kAppDelegate);
}


//
// Metadata
//

+ (void)loadMetadata:(NSString *)path withCompletionBlock:(void(^)(DBMetadata *metadata, NSError *error))block {
    objc_setAssociatedObject(kAppDelegate, "loadMetadata:", [block copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [[DroppinBadassBlocks getInstance]loadMetadata:path];
}

- (void)loadMetadata:(NSString *)path atRev:(NSString *)rev withCompletionBlock:(void(^)(DBMetadata *metadata, NSError *error))block {
    objc_setAssociatedObject(kAppDelegate, "loadMetadata:", [block copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [[DroppinBadassBlocks getInstance]loadMetadata:path atRev:rev];
}

- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata *)metadata {
    void(^block)(DBMetadata *metadata, NSError *error) = objc_getAssociatedObject(kAppDelegate, "loadMetadata:");
    block(metadata, nil);
    Block_release(block);
    objc_removeAssociatedObjects(kAppDelegate);
}

- (void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError*)error {
    void(^block)(DBMetadata *metadata, NSError *error) = objc_getAssociatedObject(kAppDelegate, "loadMetadata:");
    block(nil, error);
    Block_release(block);
    objc_removeAssociatedObjects(kAppDelegate);
}
            
@end
