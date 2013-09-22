//
//  NSString+mods.m
//  TwoFace
//
//  Created by Nathaniel Symer on 6/24/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "NSString+mods.h"

@implementation NSString (mods)

+ (NSString *)fileSizePrettify:(float)fileSize {
    if (fileSize < 1024) {
        return [NSString stringWithFormat:@"%.0f Byte%@",fileSize,(fileSize > 1)?@"s":@""];
    } else if (fileSize < pow(1024, 2) && fileSize > 1024) {
        return [NSString stringWithFormat:@"%.0f KB",(fileSize/1024)];
    } else if (fileSize < pow(1024, 3) && fileSize > pow(1024, 2)) {
        return [NSString stringWithFormat:@"%.0f MB",(fileSize/pow(1024, 2))];
    }
    return [NSString stringWithFormat:@"%.0f GB",(fileSize/pow(1024, 3))];
}

- (CGFloat)withWithFont:(UIFont *)font {
    return [self widthForHeight:[self sizeWithAttributes:@{NSFontAttributeName:font}].height font:font];
}

- (CGFloat)widthForHeight:(float)height font:(UIFont *)font {
    return [self boundingRectWithSize:CGSizeMake(MAXFLOAT, height) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:font} context:nil].size.width;
    //return [self sizeWithFont:font constrainedToSize:CGSizeMake(MAXFLOAT, height) lineBreakMode:NSLineBreakByClipping].width;
}

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
    NSURL *newURL = [[NSURL alloc]initWithScheme:url.scheme host:url.host path:newPath];
    return newURL.absoluteString;
}

- (NSString *)stringByDeletingLastPathComponent_URLSafe {
    NSURL *url = [NSURL URLWithString:self];
    NSString *newPath = [url.path stringByDeletingLastPathComponent];
    NSURL *newURL = [[NSURL alloc]initWithScheme:url.scheme host:url.host path:newPath];
    return newURL.absoluteString;
}

- (NSString *)stringByDeletingPathExtension_URLSafe {
    NSURL *url = [NSURL URLWithString:self];
    NSString *newPath = [url.path stringByDeletingPathExtension];
    NSURL *newURL = [[NSURL alloc]initWithScheme:url.scheme host:url.host path:newPath];
    return newURL.absoluteString;
}

- (NSString *)stringByAppendingPathExtension_URLSafe:(NSString *)str {
    NSURL *url = [NSURL URLWithString:self];
    NSString *newPath = [url.path stringByAppendingPathExtension:str];
    NSURL *newURL = [[NSURL alloc]initWithScheme:url.scheme host:url.host path:newPath];
    return newURL.absoluteString;
}

@end
