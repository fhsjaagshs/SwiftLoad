//
//  MIMEUtils.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 12/7/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "MIMEUtils.h"

@implementation MIMEUtils

+ (NSString *)fileMIMEType:(NSString *)file {
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)file.pathExtension.lowercaseString, nil);
    CFStringRef MIMEType = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType);
    CFRelease(UTI);
    return (__bridge NSString *)MIMEType;
}

+ (BOOL)isVideoFile:(NSString *)file {
    NSString *ext = file.pathExtension.lowercaseString;
    NSArray *fileTypes = @[@"mov", @"mp4", @"mpv", @"3gp" ];
    return [fileTypes containsObject:ext];
}

+ (BOOL)isTextFile:(NSString *)file {
    NSString *ext = file.pathExtension.lowercaseString;
    NSArray *fileTypes = @[@"cfg", @"conf", @"cs", @"h", @"j", @"list", @"log", @"nib", @"plist", @"script", @"strings", @"txt", @"xib", @"md", @"markdown", @"bat", @"xml", @"erb", @""];
    
    if ([fileTypes containsObject:ext]) {
        return YES;
    } else {
        
        if ([ext containsString:@"htm"]) {
            return YES;
        }
        
        if ([ext containsString:@"ml"]) {
            return YES;
        }
        
        if ([ext containsString:@"json"]) {
            return YES;
        }
        
        CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)file.pathExtension.lowercaseString, nil);
        NSString *uti = (__bridge NSString *)UTI;
        CFRelease(UTI);
        
        if ([uti containsString:@"source"]) {
            return YES;
        }
        
        if ([uti containsString:@"script"]) {
            return YES;
        }
    }
    
    return NO;
}

+ (BOOL)isDocumentFile:(NSString *)file {
    NSString *ext = file.pathExtension.lowercaseString;
    NSArray *fileTypes = @[@"rtf", @"pdf", @"doc", @"docx", @"xls", @"xlsx", @"ppt", @"pptx", @"pps", @"pages", @"key", @"numbers"];
    return [fileTypes containsObject:ext];
}

+ (BOOL)isImageFile:(NSString *)file {
    NSString *ext = file.pathExtension.lowercaseString;
    NSArray *fileTypes = @[@"tiff", @"tif", @"jpg", @"jpeg", @"gif", @"png", @"bmp", @"BMPf", @"ico", @"cur", @"xbm"];
    return [fileTypes containsObject:ext];
}

+ (BOOL)isAudioFile:(NSString *)file {
    NSString *ext = file.pathExtension.lowercaseString;
    NSArray *fileTypes = @[@"mp3", @"wav", @"m4a", @"aac", @"pcm"];
    return [fileTypes containsObject:ext];
}

+ (BOOL)isHTMLFile:(NSString *)file {
    NSString *ext = file.pathExtension.lowercaseString;
    NSArray *fileTypes = @[@"html", @"htm", @"xhtml", @"shtml", @"shtm", @"xhtm", @"webarchive"];
    return [fileTypes containsObject:ext];
}

@end
