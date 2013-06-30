//
//  CentralFactory.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/29/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CentralFactory : NSObject

+ (CentralFactory *)sharedFactory;

- (void)loadDatabase;

@property (nonatomic, retain) FMDatabase *database;
@property (nonatomic, retain) NSString *userID;

@end
