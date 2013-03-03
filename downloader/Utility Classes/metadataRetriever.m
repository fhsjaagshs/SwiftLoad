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
    
    err = AudioFileOpenURL((CFURLRef)fileURL, kAudioFileReadPermission, 0, &fileID);
    if (err != noErr) {
        return [NSArray arrayWithObjects:@"---", @"---", @"---", nil];
    }
    
    CFDictionaryRef piDict = nil;
    UInt32 piDataSize = sizeof(piDict);
    
    err = AudioFileGetProperty(fileID, kAudioFilePropertyInfoDictionary, &piDataSize, &piDict);
    if (err != noErr) {
        return [[[NSArray alloc]initWithObjects:@"---", @"---", @"---", nil]autorelease];
    }
    
    NSString *artistCF = (NSString *)CFDictionaryGetValue(piDict, CFSTR(kAFInfoDictionary_Artist));
    NSString *songCF = (NSString *)CFDictionaryGetValue(piDict, CFSTR(kAFInfoDictionary_Title));
    NSString *albumCF = (NSString *)CFDictionaryGetValue(piDict, CFSTR(kAFInfoDictionary_Album));
    
    NSString *artist = [NSString stringWithFormat:@"%@",artistCF];
    NSString *song = [NSString stringWithFormat:@"%@",songCF];
    NSString *album = [NSString stringWithFormat:@"%@",albumCF];

    NSString *artistNil = @"---";
    NSString *songNil = @"---";
    NSString *albumNil = @"---";
    
    BOOL artistIsNil = [artist isEqualToString:@"(null)"];
    BOOL albumIsNil = [album isEqualToString:@"(null)"];
    BOOL songIsNil = [song isEqualToString:@"(null)"];
    
    NSMutableArray *initArray = [NSMutableArray arrayWithCapacity:10];
    
    if (artistIsNil) {
        [initArray addObject:artistNil];
    } else {
        [initArray addObject:artist];
    }
    if (songIsNil) {
        [initArray addObject:songNil];
    } else {
        [initArray addObject:song];
    } 
    
    if (albumIsNil) {
        [initArray addObject:albumNil];
    } else {
        [initArray addObject:album];
    }
    
    CFRelease(piDict);

    return [NSArray arrayWithArray:initArray];
}

@end
