//
//  CompressionTask.m
//  Swift
//
//  Created by Nathaniel Symer on 7/28/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "CompressionTask.h"

@interface CompressionTask ()

@property (nonatomic, strong) NSArray *itemsToCompress;
@property (nonatomic, strong) NSString *zipFileLocation;

@end

@implementation CompressionTask

+ (CompressionTask *)taskWithItems:(NSArray *)items andZipFile:(NSString *)zipFile {
    return [[[self class]alloc]initWithItems:items andZipFile:zipFile];
}

- (id)initWithItems:(NSArray *)items andZipFile:(NSString *)zipFile {
    self = [super init];
    if (self) {
        self.itemsToCompress = items;
        self.zipFileLocation = zipFile;
    }
    return self;
}

@end
