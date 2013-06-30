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
    return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0]stringByAppendingPathComponent:@"database.db"];
}

- (BOOL)loadDB {
    if (!db) {
        if (sqlite3_open([[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0]stringByAppendingPathComponent:@"database.db"]UTF8String], &db) != SQLITE_OK ) {
            sqlite3_close(db);
            return NO;
        }
    }
    return YES;
}

- (void)insertEntriesIntoDB:(NSArray *)array {
    sqlite3 *db;
    sqlite3_open([[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0]stringByAppendingPathComponent:@"database.db"]UTF8String], &db);
    
    sqlite3_stmt *stmt;
    const char *pzTest;
    char *szSQL = "INSERT INTO dropbox_data (FirstName, LastName, Age) values (?,?,?)";
    
    sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, nil);
    
    int rc = sqlite3_prepare(db, szSQL, strlen(szSQL), &stmt, &pzTest);
    
    if (rc == SQLITE_OK) {
        // bind the value
        //sqlite3_bind_text(stmt, 1, fn, strlen(fn), 0);
        //sqlite3_bind_text(stmt, 2, ln, strlen(ln), 0);
        //sqlite3_bind_int(stmt, 3, age);
        
        // commit
        sqlite3_step(stmt);
        sqlite3_finalize(stmt);
        
        
        sqlite3_clear_bindings(stmt);
        sqlite3_reset(stmt);
    }
    
    sqlite3_exec(db, "END TRANSACTION", NULL, NULL, nil);
    
    sqlite3_close(db);
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
