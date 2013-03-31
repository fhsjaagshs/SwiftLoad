//
//  UIView+Dropbox_Blocks.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 3/30/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

/*__block int b = 0;
void* blk = ^(id self, int a) {
    b += a;
    return b;
};
blk = Block_copy(blk);
IMP imp = imp_implementationWithBlock(blk);
char *type = block_copyIMPTypeEncoding_np(blk);
assert(NULL != type);
class_addMethod((objc_getMetaClass("Foo")), @selector(count:), imp, type);
free(type);
assert(2 == [Foo count:2]);
assert(6 == [Foo count:4]);*/

#import "DroppinBadassBlocks.h"
#import <DropboxSDK/DBRestClient.h>
#import <objc/runtime.h>

//void(^metadataBlock)(DBMetadata *metadata, NSError *error);
static NSString * const MetadataBlockStringKey = @"mbsk";
static NSString * const DownloadBlockStringKey = @"dbsk";
static NSString * const LinkBlockStringKey = @"lbsk";

static char const * const MetadataBlockKey = "mbk";
static char const * const DownloadBlockKey = "dbk";
static char const * const LinkBlockKey = "lbk";

@implementation DroppinBadassBlocks

+ (id)getInstance {
    DroppinBadassBlocks *restClient = [[DroppinBadassBlocks alloc]initWithSession:[DBSession sharedSession]];
    restClient.delegate = restClient;
    return restClient;
}

+ (id)linkBlock {
    return objc_getAssociatedObject(LinkBlockStringKey, LinkBlockKey);
}

+ (void)setLinkBlock:(id)newblock {
    objc_setAssociatedObject(LinkBlockStringKey, LinkBlockKey, [newblock copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (id)downloadBlock {
    return objc_getAssociatedObject(DownloadBlockStringKey, DownloadBlockKey);
}

+ (void)setDownloadBlock:(id)newblock {
    objc_setAssociatedObject(DownloadBlockStringKey, DownloadBlockKey, [newblock copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (id)metadataBlock {
    return objc_getAssociatedObject(MetadataBlockStringKey, MetadataBlockKey);
}

+ (void)setMetadataBlock:(id)newblock {
    objc_setAssociatedObject(MetadataBlockStringKey, MetadataBlockKey, newblock, OBJC_ASSOCIATION_COPY_NONATOMIC);
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
    [DroppinBadassBlocks setMetadataBlock:block];
    [[DroppinBadassBlocks getInstance]loadMetadata:path];
}

- (void)loadMetadata:(NSString *)path atRev:(NSString *)rev withCompletionBlock:(void(^)(DBMetadata *metadata, NSError *error))block {
    [DroppinBadassBlocks setMetadataBlock:block];
    [[DroppinBadassBlocks getInstance]loadMetadata:path atRev:rev];
}

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
    void(^metadataBlock)(DBMetadata *metadata, NSError *error) = [DroppinBadassBlocks metadataBlock];
    metadataBlock(metadata, nil);
}

- (void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError *)error {
    void(^metadataBlock)(DBMetadata *metadata, NSError *error) = [DroppinBadassBlocks metadataBlock];
    metadataBlock(nil, error);
}
            
@end
