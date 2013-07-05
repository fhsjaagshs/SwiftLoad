//
//  NSString+mods.m
//  TwoFace
//
//  Created by Nathaniel Symer on 6/24/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "NSString+mods.h"

@implementation NSString (mods)

- (NSString *)percentSanitize {
    return [self stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)stringByTrimmingWhitespace {
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)stringByRemovingHTMLEntities {
    NSString *me = self;
    me = [me stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
    me = [me stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
    me = [me stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
    me = [me stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
    me = [me stringByReplacingOccurrencesOfString:@"&circ;" withString:@"^"];
    me = [me stringByReplacingOccurrencesOfString:@"&tilde;" withString:@"~"];
    me = [me stringByReplacingOccurrencesOfString:@"&dagger;" withString:@"†"];
    me = [me stringByReplacingOccurrencesOfString:@"&Dagger;" withString:@"‡"];
    return me;
}

- (NSString *)stringByCapitalizingFirstLetter {
    return [self stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[self substringToIndex:1]uppercaseString]];
}

- (int)occurencesOfString:(NSString *)string {
    return ([self componentsSeparatedByString:string].count-1);
}

- (BOOL)containsString:(NSString *)otherString {
    return !([self rangeOfString:otherString].location == NSNotFound);
}

- (NSString *)stringByTrimmingExtraInternalSpacing {
    return [self stringByReplacingOccurrencesOfString:@"  " withString:@" "];
}

- (NSString *)stringBySanitizingForFilename {
    return [[self componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/\\?%*|\"<>"]]componentsJoinedByString:@""];
}

- (NSString *)stringByAppendingPathComponent_URLSafe:(NSString *)str {
    NSURL *url = [NSURL URLWithString:self];
    NSString *newPath = [url.path stringByAppendingPathComponent:str];
    NSURL *newURL = [[[NSURL alloc]initWithScheme:url.scheme host:url.host path:newPath]autorelease];
    return newURL.absoluteString;
}

- (NSString *)stringByDeletingLastPathComponent_URLSafe {
    NSURL *url = [NSURL URLWithString:self];
    NSString *newPath = [url.path stringByDeletingLastPathComponent];
    NSURL *newURL = [[[NSURL alloc]initWithScheme:url.scheme host:url.host path:newPath]autorelease];
    return newURL.absoluteString;
}

- (NSString *)stringByDeletingPathExtension_URLSafe {
    NSURL *url = [NSURL URLWithString:self];
    NSString *newPath = [url.path stringByDeletingPathExtension];
    NSURL *newURL = [[[NSURL alloc]initWithScheme:url.scheme host:url.host path:newPath]autorelease];
    return newURL.absoluteString;
}

- (NSString *)stringByAppendingPathExtension_URLSafe:(NSString *)str {
    NSURL *url = [NSURL URLWithString:self];
    NSString *newPath = [url.path stringByAppendingPathExtension:str];
    NSURL *newURL = [[[NSURL alloc]initWithScheme:url.scheme host:url.host path:newPath]autorelease];
    return newURL.absoluteString;
}

@end
