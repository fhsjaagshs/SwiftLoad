//
//  SFTPCreds.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 7/6/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "SFTPCreds.h"

static NSString * const kCredentialsKeychainIdentifier = @"com.swiftload.sftp_credentials";

@implementation SFTPCreds

+ (void)removeCredsForURL:(NSURL *)ftpurl {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[SimpleKeychain load:kCredentialsKeychainIdentifier]];
    [dict removeObjectForKey:ftpurl.host];
    [SimpleKeychain save:kCredentialsKeychainIdentifier data:dict];
}

+ (void)saveUsername:(NSString *)username andPassword:(NSString *)password forURL:(NSURL *)ftpurl {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[SimpleKeychain load:kCredentialsKeychainIdentifier]];
    [dict setObject:@{ @"username": username, @"password": password } forKey:ftpurl.host];
    [SimpleKeychain save:kCredentialsKeychainIdentifier data:dict];
}

+ (NSDictionary *)getCredsForURL:(NSURL *)ftpurl {
    return [[NSMutableDictionary dictionaryWithDictionary:[SimpleKeychain load:kCredentialsKeychainIdentifier]]objectForKey:ftpurl.host];
}

@end
