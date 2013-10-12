//
//  NSString+MIME.m
//  Swift
//
//  Created by Nathaniel Symer on 10/12/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "NSString+MIME.h"

@implementation NSString (MIME)

- (NSString *)MIMEType {
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)self.pathExtension.lowercaseString, nil);
    CFStringRef MIMEType = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType);
    CFRelease(UTI);
    return (__bridge NSString *)MIMEType;
}

- (BOOL)isVideoFile {
    NSArray *fileTypes = @[@"mov", @"mp4", @"mpv", @"3gp"];
    return [fileTypes containsObject:self.pathExtension.lowercaseString];
}

- (BOOL)isTextFile {
    NSArray *fileTypes = @[@"cfg", @"conf", @"cs", @"h", @"j", @"list", @"log", @"nib", @"plist", @"script", @"strings", @"txt", @"xib", @"md", @"markdown", @"bat", @"xml", @"erb", @""];
    
    if ([fileTypes containsObject:self.pathExtension.lowercaseString]) {
        return YES;
    } else {
        
        if ([self.pathExtension.lowercaseString containsString:@"htm"]) {
            return YES;
        }
        
        if ([self.pathExtension.lowercaseString containsString:@"ml"]) {
            return YES;
        }
        
        if ([self.pathExtension.lowercaseString containsString:@"json"]) {
            return YES;
        }
        
        CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)self.pathExtension.lowercaseString, nil);
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

- (BOOL)isDocumentFile {
    NSArray *fileTypes = @[@"rtf", @"pdf", @"doc", @"docx", @"xls", @"xlsx", @"ppt", @"pptx", @"pps", @"pages", @"key", @"numbers"];
    return [fileTypes containsObject:self.pathExtension.lowercaseString];
}

- (BOOL)isImageFile {
    NSArray *fileTypes = @[@"tiff", @"tif", @"jpg", @"jpeg", @"gif", @"png", @"bmp", @"BMPf", @"ico", @"cur", @"xbm"];
    return [fileTypes containsObject:self.pathExtension.lowercaseString];
}

- (BOOL)isAudioFile {
    NSArray *fileTypes = @[@"mp3", @"wav", @"m4a", @"aac"];
    return [fileTypes containsObject:self.pathExtension.lowercaseString];
}

- (BOOL)isHTMLFile {
    NSArray *fileTypes = @[@"html", @"htm", @"xhtml", @"shtml", @"shtm", @"xhtm", @"webarchive"];
    return [fileTypes containsObject:self.pathExtension.lowercaseString];
}

@end
