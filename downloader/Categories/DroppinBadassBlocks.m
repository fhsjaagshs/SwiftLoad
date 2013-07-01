//
//  DroppingBadassBlocks.m
//  DroppingBadassBlocks
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

static NSString * const MetadataBlockStringKey = @"mbsk";
static NSString * const DownloadProgressBlockStringKey = @"dbsk-1";
static NSString * const DownloadBlockStringKey = @"dbsk";
static NSString * const LinkBlockStringKey = @"lbsk";
static NSString * const DeltaBlockStringKey = @"dbsk";
static NSString * const UploadBlockStringKey = @"ubsk";
static NSString * const UploadProgressBlockStringKey = @"ubsk-1";
static NSString * const loadAccountInfoBlockStringKey = @"laicsk";
static NSString * const instanceString = @"instance";

static char const * const MetadataBlockKey = "mbk";
static char const * const DownloadProgressBlockKey = "dbsk-1";
static char const * const DownloadBlockKey = "dbk";
static char const * const LinkBlockKey = "lbk";
static char const * const DeltaBlockKey = "dbk";
static char const * const UploadBlockKey = "ubk";
static char const * const UploadProgressBlockKey = "ubk-1";
static char const * const loadAccountInfoBlockKey = "laick";
static char const * const instance = "instance";


@interface DroppinBadassBlocks () <DBRestClientDelegate>
+ (id)getInstance;
+ (id)uploadBlock;
+ (void)setUploadBlock:(id)newblock;
+ (id)uploadProgressBlock;
+ (void)setUploadProgressBlock:(id)newblock;
+ (id)deltaBlock;
+ (void)setDeltaBlock:(id)newblock;
+ (id)linkBlock;
+ (void)setLinkBlock:(id)newblock;
+ (id)downloadProgressBlock;
+ (void)setDownloadProgressBlock:(id)newblock;
+ (id)downloadBlock;
+ (void)setDownloadBlock:(id)newblock;
+ (id)metadataBlock;
+ (void)setMetadataBlock:(id)newblock;
+ (id)loadAccountInfoBlock;
+ (void)setAccountInfoBlock:(id)newblock;
@end

@implementation DroppinBadassBlocks

+ (id)getInstance {
    DroppinBadassBlocks *restClient = objc_getAssociatedObject(instanceString, instance);
    
    if (!restClient) {
        restClient = [[DroppinBadassBlocks alloc]initWithSession:[DBSession sharedSession]];
        objc_setAssociatedObject(instanceString, instance, restClient, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    restClient.delegate = restClient;
    return restClient;
}

+ (id)uploadBlock {
    return objc_getAssociatedObject(UploadBlockStringKey, UploadBlockKey);
}

+ (void)setUploadBlock:(id)newblock {
    objc_setAssociatedObject(UploadBlockStringKey, UploadBlockKey, newblock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

+ (id)uploadProgressBlock {
    return objc_getAssociatedObject(UploadProgressBlockStringKey, UploadProgressBlockKey);
}

+ (void)setUploadProgressBlock:(id)newblock {
    objc_setAssociatedObject(UploadProgressBlockStringKey, UploadProgressBlockKey, newblock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

+ (id)deltaBlock {
    return objc_getAssociatedObject(DeltaBlockStringKey, DeltaBlockKey);
}

+ (void)setDeltaBlock:(id)newblock {
    objc_setAssociatedObject(DeltaBlockStringKey, DeltaBlockKey, newblock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

+ (id)linkBlock {
    return objc_getAssociatedObject(LinkBlockStringKey, LinkBlockKey);
}

+ (void)setLinkBlock:(id)newblock {
    objc_setAssociatedObject(LinkBlockStringKey, LinkBlockKey, newblock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

+ (id)downloadProgressBlock {
    return objc_getAssociatedObject(DownloadProgressBlockStringKey, DownloadProgressBlockKey);
}

+ (void)setDownloadProgressBlock:(id)newblock {
    objc_setAssociatedObject(DownloadProgressBlockStringKey, DownloadProgressBlockKey, newblock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

+ (id)downloadBlock {
    return objc_getAssociatedObject(DownloadBlockStringKey, DownloadBlockKey);
}

+ (void)setDownloadBlock:(id)newblock {
    objc_setAssociatedObject(DownloadBlockStringKey, DownloadBlockKey, newblock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

+ (id)metadataBlock {
    return objc_getAssociatedObject(MetadataBlockStringKey, MetadataBlockKey);
}

+ (void)setMetadataBlock:(id)newblock {
    objc_setAssociatedObject(MetadataBlockStringKey, MetadataBlockKey, newblock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

+ (id)loadAccountInfoBlock {
    return objc_getAssociatedObject(loadAccountInfoBlockStringKey, loadAccountInfoBlockKey);
}

+ (void)setAccountInfoBlock:(id)newblock {
    objc_setAssociatedObject(loadAccountInfoBlockStringKey, loadAccountInfoBlockKey, newblock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

//
// Uploading
//

+ (void)uploadFile:(NSString *)filename toPath:(NSString *)path withParentRev:(NSString *)parentRev fromPath:(NSString *)sourcePath withBlock:(void(^)(NSString *destPath, NSString *srcPath, DBMetadata *metadata, NSError *error))block andProgressBlock:(void(^)(CGFloat progress, NSString *destPath, NSString *scrPath))pBlock {
    [DroppinBadassBlocks setUploadBlock:block];
    [DroppinBadassBlocks setUploadProgressBlock:pBlock];
    [[DroppinBadassBlocks getInstance]uploadFile:filename toPath:path withParentRev:parentRev fromPath:sourcePath];
}

- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath metadata:(DBMetadata *)metadata {
    void(^block)(NSString *destPath, NSString *srcPath, DBMetadata *metadata, NSError *error) = [DroppinBadassBlocks uploadBlock];
    block(destPath, srcPath, metadata, nil);
}

- (void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error {
    void(^block)(NSString *destPath, NSString *srcPath, DBMetadata *metadata, NSError *error) = [DroppinBadassBlocks uploadBlock];
    block(nil, nil, nil, error);
}

- (void)restClient:(DBRestClient *)client uploadProgress:(CGFloat)progress forFile:(NSString *)destPath from:(NSString *)srcPath {
    void(^block)(CGFloat progress, NSString *destPath, NSString *scrPath) = [DroppinBadassBlocks uploadProgressBlock];
    block(progress, destPath, srcPath);
}



//
// Delta
//

+ (void)loadDelta:(NSString *)cursor withCompletionHandler:(void(^)(NSArray *entries, NSString *cursor, BOOL hasMore, BOOL shouldReset, NSError *error))block {
    [DroppinBadassBlocks setDeltaBlock:block];
    [[DroppinBadassBlocks getInstance]loadDelta:cursor];
}

- (void)restClient:(DBRestClient *)client loadedDeltaEntries:(NSArray *)entries reset:(BOOL)shouldReset cursor:(NSString *)cursor hasMore:(BOOL)hasMore {
    void(^block)(NSArray *entries, NSString *cursor, BOOL hasMore, BOOL shouldReset, NSError *error) = [DroppinBadassBlocks deltaBlock];
    block(entries, cursor, hasMore, shouldReset, nil);
}

- (void)restClient:(DBRestClient *)client loadDeltaFailedWithError:(NSError *)error {
    void(^block)(NSArray *entries, NSString *cursor, NSError *error) = [DroppinBadassBlocks deltaBlock];
    block(nil, nil, error);
}

//
// Links
//

+ (void)loadSharableLinkForFile:(NSString *)path andCompletionBlock:(void(^)(NSString *link, NSString *path, NSError *error))block {
    [DroppinBadassBlocks setLinkBlock:block];
    [[DroppinBadassBlocks getInstance]loadSharableLinkForFile:path shortUrl:YES];
}

- (void)restClient:(DBRestClient *)restClient loadedSharableLink:(NSString *)link forFile:(NSString *)path {
    void(^block)(NSString *link, NSString *path, NSError *error) = [DroppinBadassBlocks linkBlock];
    block(link, path, nil);
}

- (void)restClient:(DBRestClient *)restClient loadSharableLinkFailedWithError:(NSError *)error {
    void(^block)(NSString *link, NSString *path, NSError *error) = [DroppinBadassBlocks linkBlock];
    block(nil, nil, error);
}

//
// File Downloading
//

+ (void)loadFile:(NSString *)path intoPath:(NSString *)destinationPath withCompletionBlock:(void(^)(DBMetadata *metadata, NSError *error))block andProgressBlock:(void(^)(float progress))progBlock {
    [DroppinBadassBlocks setDownloadBlock:block];
    [DroppinBadassBlocks setDownloadProgressBlock:progBlock];
    [[DroppinBadassBlocks getInstance]loadFile:path intoPath:destinationPath];
}

- (void)restClient:(DBRestClient *)client loadedFile:(NSString *)destPath contentType:(NSString *)contentType metadata:(DBMetadata *)metadata {
    void(^block)(DBMetadata *metadata, NSError *error) = [DroppinBadassBlocks downloadBlock];
    block(metadata, nil);
}

- (void)restClient:(DBRestClient *)client loadProgress:(CGFloat)progress forFile:(NSString *)destPath {
    void(^block)(float progress) = [DroppinBadassBlocks downloadProgressBlock];
    block(progress);
}

- (void)restClient:(DBRestClient *)client loadFileFailedWithError:(NSError *)error {
    void(^block)(DBMetadata *metadata, NSError *error) = [DroppinBadassBlocks downloadBlock];
    block(nil, error);
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

//
// Account Info Loading
//

+ (void)loadAccountInfoWithCompletionBlock:(void(^)(DBAccountInfo *info, NSError *error))block {
    [DroppinBadassBlocks setAccountInfoBlock:block];
    [[DroppinBadassBlocks getInstance]loadAccountInfo];
}

- (void)restClient:(DBRestClient *)client loadedAccountInfo:(DBAccountInfo *)info {
    void(^block)(DBAccountInfo *, NSError *) = [DroppinBadassBlocks loadAccountInfoBlock];
    block(info, nil);
}

- (void)restClient:(DBRestClient *)client loadAccountInfoFailedWithError:(NSError *)error {
    void(^block)(DBAccountInfo *, NSError *) = [DroppinBadassBlocks loadAccountInfoBlock];
    block(nil, error);
}

//
// Cancellation
//

+ (void)cancel {
    [[DroppinBadassBlocks getInstance]cancelAllRequests];
}
            
@end
