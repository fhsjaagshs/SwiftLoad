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
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)[[file pathExtension]lowercaseString], nil);
    CFStringRef MIMEType = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType);
    CFRelease(UTI);
    return [(NSString *)MIMEType autorelease];
}

+ (BOOL)isVideoFile:(NSString *)file {
    NSString *ext = [[file pathExtension]lowercaseString];
    NSArray *fileTypes = [NSArray arrayWithObjects:@"mov", @"mp4", @"mpv", @"3gp", nil];
    return [fileTypes containsObject:ext];
}

+ (BOOL)isTextFile:(NSString *)file {
    NSString *ext = [[file pathExtension]lowercaseString];
    NSArray *fileTypes = [NSArray arrayWithObjects:@"c", @"cfg", @"conf", @"cpp", @"cs", @"java", @"rb", @"py", @"h", @"j", @"java", @"js", @"list", @"log", @"m", @"mm", @"nib", @"php", @"plist", @"script", @"sh", @"strings", @"txt", @"xib", @"html", @"htm", @"xhtml", @"shtml", @"shtm", @"xhtm", @"md", @"markdown", @"bat", @"pl", @"", nil];
    return [fileTypes containsObject:ext];
}

+ (BOOL)isTextFile_WebSafe:(NSString *)file {
    NSString *ext = [[file pathExtension]lowercaseString];
    NSArray *fileTypes = [NSArray arrayWithObjects:@"c", @"cfg", @"conf", @"cpp", @"cs", @"java", @"h", @"j", @"java", @"list", @"log", @"m", @"mm", @"nib", @"plist", @"strings", @"txt", @"xib", @"md", @"markdown", @"bat", nil];
    return [fileTypes containsObject:ext];
}

+ (BOOL)isDocumentFile:(NSString *)file {
    NSString *ext = [[file pathExtension]lowercaseString];
    NSArray *fileTypes = [NSArray arrayWithObjects:@"rtf", @"pdf", @"doc", @"docx", @"xls", @"xlsx", @"ppt", @"pptx", @"pps", @"pages", @"key", @"numbers", nil];
    return [fileTypes containsObject:ext];
}

+ (BOOL)isImageFile:(NSString *)file {
    NSString *ext = [[file pathExtension]lowercaseString];
    NSArray *fileTypes = [NSArray arrayWithObjects:@"png", @"gif", @"jpg", @"jpeg", @"tiff", @"svg", nil];
    return [fileTypes containsObject:ext];
}

+ (BOOL)isAudioFile:(NSString *)file {
    NSString *ext = [[file pathExtension]lowercaseString];
    NSArray *fileTypes = [NSArray arrayWithObjects:@"mp3", @"wav", @"m4a", @"aac", @"pcm", nil];
    return [fileTypes containsObject:ext];
}

+ (BOOL)isHTMLFile:(NSString *)file {
    NSString *ext = [[file pathExtension]lowercaseString];
    NSArray *fileTypes = [NSArray arrayWithObjects:@"html", @"htm", @"xhtml", @"shtml", @"shtm", @"xhtm", @"webarchive", nil];
    return [fileTypes containsObject:ext];
}

@end
