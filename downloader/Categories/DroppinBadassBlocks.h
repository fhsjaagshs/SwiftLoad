//
//  DroppingBadassBlocks.h
//  DroppingBadassBlocks
//
//  Created by Nathaniel Symer on 3/30/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DroppinBadassBlocks : DBRestClient

+ (void)loadSharableLinkForFile:(NSString *)path andCompletionBlock:(void(^)(NSString *link, NSString *path, NSError *error))block;
+ (void)loadFile:(NSString *)path intoPath:(NSString *)destinationPath withCompletionBlock:(void(^)(DBMetadata *metadata, NSError *error))block andProgressBlock:(void(^)(CGFloat progress))progBlock;
+ (void)loadMetadata:(NSString *)path withCompletionBlock:(void(^)(DBMetadata *metadata, NSError *error))block;
+ (void)loadDelta:(NSString *)cursor withCompletionHandler:(void(^)(NSArray *entries, NSString *cursor, NSError *error))block;

@end
