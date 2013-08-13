//
//  ID3Editor.h
//  TagLibTest
//
//  Created by Nathaniel Symer on 8/13/13.
//  Copyright (c) 2013 natesymer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ID3Editor : NSObject

+ (NSDictionary *)loadTagFromFile:(NSString *)file;

+ (BOOL)setTitle:(NSString *)title forMP3AtPath:(NSString *)path;
+ (BOOL)setAlbum:(NSString *)album forMP3AtPath:(NSString *)path;
+ (BOOL)setArtist:(NSString *)artist forMP3AtPath:(NSString *)path;

@end
