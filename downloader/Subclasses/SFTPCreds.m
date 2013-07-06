//
//  SFTPCreds.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 7/6/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "SFTPCreds.h"

static NSString * const kCredentialsKeychainIdentifier = @"com.swiftload.sftp.credentials";

@implementation SFTPCreds

+ (void)removeCredsForURL:(NSURL *)ftpurl {
    [[Keychain sharedKeychain]setIdentifier:kCredentialsKeychainIdentifier];
    NSString *keychainData = (NSString *)[[Keychain sharedKeychain]objectForKey:(id)kSecValueData];
    
    int index = -1;
    
    NSMutableArray *triples = [NSMutableArray arrayWithArray:[keychainData componentsSeparatedByString:@","]];
    
    for (NSString *string in triples) {
        NSArray *components = [keychainData componentsSeparatedByString:@":"];
        NSString *host = [components objectAtIndex:2];
        if ([host isEqualToString:ftpurl.host]) {
            index = [triples indexOfObject:string];
            break;
        }
    }
    
    [triples removeObjectAtIndex:index];
    NSString *final = [triples componentsJoinedByString:@","];
    [[Keychain sharedKeychain]setObject:final forKey:(id)kSecValueData];
}

+ (void)saveUsername:(NSString *)username andPassword:(NSString *)password forURL:(NSURL *)ftpurl {
    [[Keychain sharedKeychain]setIdentifier:kCredentialsKeychainIdentifier];
    NSString *keychainData = (NSString *)[[Keychain sharedKeychain]objectForKey:(id)kSecValueData];
    int index = -1;
    
    NSMutableArray *triples = [NSMutableArray arrayWithArray:[keychainData componentsSeparatedByString:@","]];
    
    for (NSString *string in [[triples mutableCopy]autorelease]) {
        
        if (string.length == 0) {
            [triples removeObject:string];
            continue;
        }
        
        NSArray *components = [string componentsSeparatedByString:@":"];
        
        NSString *host = [components objectAtIndex:2];
        if ([host isEqualToString:ftpurl.host]) {
            index = [triples indexOfObject:string];
            break;
        }
    }
    
    if (password.length == 0) {
        password = @" ";
    }
    
    NSString *concatString = [NSString stringWithFormat:@"%@:%@:%@",username, password, ftpurl.host];
    
    if (index == -1) {
        [triples addObject:concatString];
    } else {
        [triples replaceObjectAtIndex:index withObject:concatString];
    }
    
    NSString *final = [triples componentsJoinedByString:@","];
    
    [[Keychain sharedKeychain]setObject:final forKey:(id)kSecValueData];
}

+ (NSDictionary *)getCredsForURL:(NSURL *)ftpurl {
    [[Keychain sharedKeychain]setIdentifier:kCredentialsKeychainIdentifier];
    NSString *keychainData = (NSString *)[[Keychain sharedKeychain]objectForKey:(id)kSecValueData];
    
    if (keychainData.length == 0) {
        return nil;
    }
    
    // username:password:host, username:password:host, username:password:host
    
    NSString *username = nil;
    NSString *password = nil;
    
    NSArray *triples = [keychainData componentsSeparatedByString:@","];
    
    for (NSString *string in triples) {
        
        NSArray *components = [string componentsSeparatedByString:@":"];
        
        if (components.count == 0) {
            continue;
        }
        
        NSString *host = [components objectAtIndex:2];
        
        if ([host isEqualToString:ftpurl.host]) {
            username = [components objectAtIndex:0];
            password = [components objectAtIndex:1];
            break;
        }
    }
    
    if (username.length > 0 && password.length > 0) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setObject:username forKey:@"username"];
        [dict setObject:password forKey:@"password"];
        return dict;
    }
    return nil;
}

@end
