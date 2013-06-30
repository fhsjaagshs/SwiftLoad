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

- (FMDatabase *)database {
    [_database open];
    return _database;
}

- (void)setDropboxUserID:(NSString *)userID {
    if (![userID isEqualToString:_userID]) {
        [_userID release];
        _userID = [userID retain];
    }
}

- (void)loadDatabase {
    self.database = [FMDatabase databaseWithPath:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0]stringByAppendingPathComponent:@"database.db"]];
    if ([_database open]) {
        // TYPE 1 = File
        // TYPE 2 = Directory
        [_database executeQuery:@"create table if not exists DropboxData (id INTEGER PRIMARY KEY, lowercasepath VARCHAR, filename VARCHAR, date INTEGER, size INTEGER, type INTEGER, user_id VARCHAR(255)"];
    }
    [_database close];
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
    [super dealloc];
}


@end
