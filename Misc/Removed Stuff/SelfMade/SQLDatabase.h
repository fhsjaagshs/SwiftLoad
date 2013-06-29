//
//  SQLITEManager.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/29/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SQLDatabase : NSObject

- (BOOL)loadDB;
- (NSArray *)performQuery:(NSString *)query;

+ (SQLDatabase *)sharedDatabase;

@end
