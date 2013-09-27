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
    NSArray *fileTypes = @[@"mov", @"mp4", @"mpv", @"3gp"];
    return [fileTypes containsObject:file.pathExtension.lowercaseString];
}

+ (BOOL)isTextFile:(NSString *)file {
    NSArray *fileTypes = @[@"cfg", @"conf", @"cs", @"h", @"j", @"list", @"log", @"nib", @"plist", @"script", @"strings", @"txt", @"xib", @"md", @"markdown", @"bat", @"xml", @"erb", @""];
    
    if ([fileTypes containsObject:file.pathExtension.lowercaseString]) {
        return YES;
    } else {
        
        if ([file.pathExtension.lowercaseString containsString:@"htm"]) {
            return YES;
        }
        
        if ([file.pathExtension.lowercaseString containsString:@"ml"]) {
            return YES;
        }
        
        if ([file.pathExtension.lowercaseString containsString:@"json"]) {
            return YES;
        }
        
        CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)file.pathExtension.lowercaseString, nil);
        NSString *uti = (__bridge NSString *)UTI;
        
        BOOL isYES = NO;
        
        if ([uti containsString:@"source"]) {
            isYES = YES;
        }
        
        if ([uti containsString:@"script"]) {
            isYES = YES;
        }
        
        CFRelease(UTI);
        
        return isYES;
    }
    
    return NO;
}

+ (BOOL)isDocumentFile:(NSString *)file {
    NSArray *fileTypes = @[@"rtf", @"pdf", @"doc", @"docx", @"xls", @"xlsx", @"ppt", @"pptx", @"pps", @"pages", @"key", @"numbers"];
    return [fileTypes containsObject:file.pathExtension.lowercaseString];
}

+ (BOOL)isImageFile:(NSString *)file {
    NSArray *fileTypes = @[@"tiff", @"tif", @"jpg", @"jpeg", @"gif", @"png", @"bmp", @"BMPf", @"ico", @"cur", @"xbm"];
    return [fileTypes containsObject:file.pathExtension.lowercaseString];
}

+ (BOOL)isAudioFile:(NSString *)file {
    NSArray *fileTypes = @[@"mp3", @"wav", @"m4a", @"aac", @"pcm"];
    return [fileTypes containsObject:file.pathExtension.lowercaseString];
}

+ (BOOL)isHTMLFile:(NSString *)file {
    NSArray *fileTypes = @[@"html", @"htm", @"xhtml", @"shtml", @"shtm", @"xhtm", @"webarchive"];
    return [fileTypes containsObject:file.pathExtension.lowercaseString];
}

@end
