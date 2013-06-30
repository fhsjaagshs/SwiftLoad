//
//  CentralFactory.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/29/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "CentralFactory.h"

static CentralFactory *sharedInstance;

@implementation CentralFactory

- (void)loadDatabase {
    self.database = [FMDatabase databaseWithPath:[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)objectAtIndex:0]stringByAppendingPathComponent:@"database.db"]];
    [_database open];
    [_database executeUpdate:@"CREATE TABLE IF NOT EXISTS dropbox_data (id INTEGER PRIMARY KEY AUTOINCREMENT, lowercasepath TEXT DEFAULT NULL, filename TEXT DEFAULT NULL, date INTEGER, size INTEGER, type INTEGER, user_id VARCHAR(255) DEFAULT NULL);"];
}

- (id)init {
    self = [super init];
    if (self) {
        [self loadDatabase];
    }
    return self;
}

+ (CentralFactory *)sharedFactory {
    @synchronized (self) {
        if (sharedInstance == nil) {
            [[self alloc]init];
        }
    }
    return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedInstance == nil) {
            sharedInstance = [super allocWithZone:zone];
            return sharedInstance;
        }
    }
    return nil;
}

- (id)retain {
    return self;
}

- (oneway void)release {
    // Do nothing
}

- (id)autorelease {
    return self;
}

- (NSUInteger)retainCount {
    return NSUIntegerMax;
}

- (void)dealloc {
    [self setDatabase:nil];
    [self setUserID:nil];
    [super dealloc];
}


@end
