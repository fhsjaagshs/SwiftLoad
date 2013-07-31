//
//  metadataRetriever.m
//  metadataRetriever
//
//  Created by Nathaniel Symer on 12/20/11.
//  Do whatever you want with this, just don't pass it 
//  off as your own.
//

#import "metadataRetriever.h"
#import <CoreFoundation/CoreFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

@implementation metadataRetriever

+ (NSArray *)getMetadataForFile:(NSString *)filePath {
    
    AudioFileID fileID = nil;
    OSStatus err = noErr;
    
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    
    err = AudioFileOpenURL((__bridge CFURLRef)fileURL, kAudioFileReadPermission, 0, &fileID);
    if (err != noErr) {
        return [NSArray arrayWithObjects:@"---", @"---", @"---", nil];
    }
    
    CFDictionaryRef piDict = nil;
    UInt32 piDataSize = sizeof(piDict);
    
    err = AudioFileGetProperty(fileID, kAudioFilePropertyInfoDictionary, &piDataSize, &piDict);
    if (err != noErr) {
        return [NSArray arrayWithObjects:@"---", @"---", @"---", nil];
    }
    
    NSString *artist = (NSString *)CFDictionaryGetValue(piDict, CFSTR("artist")); // kAFInfoDictionary_Artist
    NSString *song = (NSString *)CFDictionaryGetValue(piDict, CFSTR("title")); // kAFInfoDictionary_Title
    NSString *album = (NSString *)CFDictionaryGetValue(piDict, CFSTR("album")); // kAFInfoDictionary_Album
    
    CFRelease(piDict);
    
    NSMutableArray *initArray = [NSMutableArray arrayWithCapacity:3];
    
    if ([artist isEqualToString:@"(null)"] || artist.length == 0) {
        [initArray addObject:@"---"];
    } else {
        [initArray addObject:artist];
    }
    if ([song isEqualToString:@"(null)"] || song.length == 0) {
        [initArray addObject:@"---"];
    } else {
        [initArray addObject:song];
    } 
    
    if ([song isEqualToString:@"(null)"] || song.length == 0) {
        [initArray addObject:@"---"];
    } else {
        [initArray addObject:album];
    }

    return [NSArray arrayWithArray:initArray];
}

@end
