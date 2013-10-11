//
//  UIApplication+Extensions.m
//  Swift
//
//  Created by Nathaniel Symer on 10/8/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "UIApplication+Extensions.h"

#include <ifaddrs.h>
#include <arpa/inet.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <netdb.h>
#include <SystemConfiguration/SCNetworkReachability.h>

@implementation UIApplication (Extensions)

- (UIWindow *)appWindow {
    return (self.windows)[0];
}

+ (NSString *)IPAddress {
    NSString *address = @"";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    
    success = getifaddrs(&interfaces);
    if (success == 0) {
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                NSString *isen0 = @(temp_addr->ifa_name);
                if([isen0 isEqualToString:@"en0"] || [isen0 isEqualToString:@"en1"]) {
                    address = @(inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr));
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    freeifaddrs(interfaces);
    return address;
}

+ (BOOL)isConnectedToWifi {
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*)&zeroAddress);
    if(reachability != NULL) {
        SCNetworkReachabilityFlags flags;
        BOOL flagsRetrieved = SCNetworkReachabilityGetFlags(reachability, &flags);
        CFRelease(reachability);
        
        if (flagsRetrieved) {
            if ((flags & kSCNetworkReachabilityFlagsReachable) == 0) {
                return NO;
            }
            
            if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
                return YES;
            }
            
            if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) || (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0)) {
                if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0) {
                    return YES;
                }
            }
        }
    }
    
    return NO;
}

+ (BOOL)isConnectedToInternet {
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*)&zeroAddress);
    if (reachability) {
        SCNetworkReachabilityFlags flags;
        BOOL flagsRetrieved = SCNetworkReachabilityGetFlags(reachability, &flags);
        CFRelease(reachability);
        
        if (flagsRetrieved) {
            if ((flags & kSCNetworkReachabilityFlagsReachable) == 0) {
                return NO;
            }
            
            if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
                return YES;
            }
            
            if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) || (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0)) {
                if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0) {
                    return YES;
                }
            }
            
            if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) {
                return YES;
            }
        }
    }
    
    return NO;
}

@end
