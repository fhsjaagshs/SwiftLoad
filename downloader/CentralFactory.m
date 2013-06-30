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
    if ([_database open]) {
        // TYPE 1 = File
        // TYPE 2 = Directory
        NSLog(@"opened");
        [_database executeQuery:@"CREATE TABLE IF NOT EXISTS DropboxData(id INTEGER PRIMARY KEY NOT NULL, lowercasepath VARCHAR NOT NULL, filename VARCHAR NOT NULL, date INTEGER NOT NULL, size INTEGER NOT NULL, type INTEGER NOT NULL, user_id VARCHAR(255) NOT NULL)"];
        NSLog(@"Error: %@",[_database lastErrorMessage]);
        [_database close];
    }
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
