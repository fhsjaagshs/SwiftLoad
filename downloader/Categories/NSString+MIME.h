//
//  NSString+MIME.h
//  Swift
//
//  Created by Nathaniel Symer on 10/12/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (MIME)

- (NSString *)UTI;
- (NSString *)MIMEType;

- (BOOL)isVideoFile;
- (BOOL)isTextFile;
- (BOOL)isDocumentFile;
- (BOOL)isImageFile;
- (BOOL)isAudioFile;
- (BOOL)isHTMLFile;

@end
