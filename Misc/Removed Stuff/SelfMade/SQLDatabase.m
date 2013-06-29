//
//  SQLITEManager.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/29/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "SQLDatabase.h"
#import "sqlite3.h"

static SQLDatabase *sharedInstance;

@interface SQLDatabase () {
    sqlite3 *db;
}

@end

@implementation SQLDatabase

+ (SQLDatabase *)sharedDatabase {
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

- (id)init {
    self = [super init];
    if (self) {
        // perhaps
    }
    return self;
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

- (NSString *)filePath {
    return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0]stringByAppendingPathComponent:@"database.sql"];
}

- (BOOL)loadDB {
    if (!db) {
        if (sqlite3_open([[self filePath] UTF8String], &db) != SQLITE_OK ) {
            sqlite3_close(db);
            return NO;
        }
    }
    return YES;
}

- (NSArray *)performQuery:(NSString *)query {
    sqlite3_stmt *statement = nil;
    const char *sql = [query UTF8String];
    if (sqlite3_prepare_v2(db, sql, -1, &statement, nil) != SQLITE_OK) {
        NSLog(@"[SQLITE] Error when preparing query!");
    } else {
        NSMutableArray *result = [NSMutableArray array];
        while (sqlite3_step(statement) == SQLITE_ROW) {
            NSMutableArray *row = [NSMutableArray array];
            for (int i=0; i<sqlite3_column_count(statement); i++) {
                int colType = sqlite3_column_type(statement, i);
                id value;
                if (colType == SQLITE_TEXT) {
                    const unsigned char *col = sqlite3_column_text(statement, i);
                    value = [NSString stringWithFormat:@"%s", col];
                } else if (colType == SQLITE_INTEGER) {
                    int col = sqlite3_column_int(statement, i);
                    value = [NSNumber numberWithInt:col];
                } else if (colType == SQLITE_FLOAT) {
                    double col = sqlite3_column_double(statement, i);
                    value = [NSNumber numberWithDouble:col];
                } else if (colType == SQLITE_NULL) {
                    value = [NSNull null];
                } else {
                    NSLog(@"[SQLITE] UNKNOWN DATATYPE");
                }
                
                if (value != nil) {
                   [row addObject:value]; 
                }
            }
            [result addObject:row];
        }
        return result;
    }
    return nil;
}

@end
