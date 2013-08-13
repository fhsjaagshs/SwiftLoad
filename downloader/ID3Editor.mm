//
//  ID3Editor.m
//  TagLibTest
//
//  Created by Nathaniel Symer on 8/13/13.
//  Copyright (c) 2013 natesymer. All rights reserved.
//

#import "ID3Editor.h"

#include "TagLibAmalgam.h"

@implementation ID3Editor

+ (BOOL)setTitle:(NSString *)title forMP3AtPath:(NSString *)path {
    TagLib::FileRef f([path UTF8String]);
    f.tag()->setTitle([title UTF8String]);
    return f.save();
}

+ (BOOL)setAlbum:(NSString *)album forMP3AtPath:(NSString *)path {
    TagLib::FileRef f([path UTF8String]);
    f.tag()->setAlbum([album UTF8String]);
    return f.save();
}

+ (BOOL)setArtist:(NSString *)artist forMP3AtPath:(NSString *)path {
    TagLib::FileRef f([path UTF8String]);
    f.tag()->setArtist([artist UTF8String]);
    return f.save();
}

@end
