//
//  NSObject+Debug.m
//  Swift
//
//  Created by Nathaniel Symer on 9/20/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "NSObject+Debug.h"
#import <objc/runtime.h>

@implementation NSObject (Debug)

- (NSDictionary *)listProperties {
    NSMutableDictionary *props = [NSMutableDictionary dictionary];
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        NSString *propertyName = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        NSLog(@"%@",propertyName);
        id propertyValue = [self valueForKey:(NSString *)propertyName];
        if (propertyValue) [props setObject:propertyValue forKey:propertyName];
    }
    free(properties);
    return props;
}

@end
