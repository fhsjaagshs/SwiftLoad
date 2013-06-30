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

@property (nonatomic, retain, getter = database) FMDatabase *database;
@property (nonatomic, retain) NSString *userID;

@end
