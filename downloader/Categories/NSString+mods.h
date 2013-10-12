//
//  NSString+mods.h
//  TwoFace
//
//  Created by Nathaniel Symer on 6/24/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (mods)

+ (NSString *)fileSizePrettify:(float)fileSize;

- (NSString *)strip;
- (CGFloat)withWithFont:(UIFont *)font;
- (CGFloat)widthForHeight:(float)height font:(UIFont *)font;
- (NSString *)percentSanitize;
- (NSString *)stringByRemovingHTMLEntities;
- (NSString *)stringByCapitalizingFirstLetter;
- (int)occurencesOfString:(NSString *)string;
- (BOOL)containsString:(NSString *)otherString;
- (NSString *)stringByTrimmingExtraInternalSpacing;
- (NSString *)stringBySanitizingForFilename;
- (NSString *)stringByAppendingPathComponent_URLSafe:(NSString *)str;
- (NSString *)stringByDeletingLastPathComponent_URLSafe;
- (NSString *)stringByDeletingPathExtension_URLSafe;
- (NSString *)stringByAppendingPathExtension_URLSafe:(NSString *)str;

@end
