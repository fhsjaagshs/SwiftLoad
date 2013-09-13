//
//  DBRestClient+SpecificCancellation.m
//  Swift
//
//  Created by Nathaniel Symer on 9/13/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "DBRestClient+SpecificCancellation.h"

@implementation DBRestClient (SpecificCancellation)

- (int)cancelAllDownloads {
    int count = loadRequests.allValues.count;
    for (DBRequest *request in loadRequests.allValues) {
        [request cancel];
    }
    [loadRequests removeAllObjects];
    return count;
}

- (int)cancelAllMiscRequests {
    int count = requests.count;
    for (DBRequest *request in requests) {
        
        NSString *url = request.request.URL.absoluteString;
        
        if (![url containsString:@"/shares/"]) {
            [request cancel];
        }
    }
    [requests removeAllObjects];
    return count;
}

- (BOOL)cancelSharableLinkLoadWithDropboxPath:(NSString *)dbPath {
    
    DBRequest *request = nil;
    
    for (DBRequest *req in requests) {
        NSString *path = req.userInfo[@"path"];
        
        if ([path isEqualToString:dbPath]) {
            
        }
    }
    
    if (request == nil) {
        return NO;
    }
    
    NSString *url = request.request.URL.absoluteString;
    
    if (![url containsString:@"/shares/"]) {
        return NO;
    }
    
    [request cancel];
    [requests removeObject:request];
    
    return YES;
}

- (BOOL)cancelUploadWithDropboxPath:(NSString *)dbPath {
    DBRequest *request = [uploadRequests objectForKey:dbPath];
    
    if (request != nil) {
        [request cancel];
        [uploadRequests removeObjectForKey:dbPath];
        return YES;
    }
    return NO;
}

- (BOOL)cancelDownloadWithDropboxPath:(NSString *)dbPath {
    DBRequest *request = [loadRequests objectForKey:dbPath];
    
    if (request != nil) {
        [request cancel];
        [loadRequests removeObjectForKey:dbPath];
        return YES;
    }
    return NO;
}

@end
