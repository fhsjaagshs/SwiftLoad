//
//  MIMEUtils.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 12/7/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MIMEUtils : NSObject

+ (NSString *)fileMIMEType:(NSString *)file;
+ (BOOL)isVideoFile:(NSString *)file;
+ (BOOL)isTextFile:(NSString *)file;
+ (BOOL)isTextFile_WebSafe:(NSString *)file;
+ (BOOL)isDocumentFile:(NSString *)file;
+ (BOOL)isImageFile:(NSString *)file;
+ (BOOL)isAudioFile:(NSString *)file;
+ (BOOL)isHTMLFile:(NSString *)file;

@end
