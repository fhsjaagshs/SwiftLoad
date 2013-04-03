//
//  AudioConverter.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 12/8/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "AudioConverter.h"

@implementation AudioConverter

+ (NSError *)convertAudioFileAtPath:(NSString *)source progressObject:(id)progressObject {
    
    OSStatus err = noErr;
    
    AudioSessionInitialize(nil, nil, nil, nil);
    
    UInt32 audioCategory = kAudioSessionCategory_MediaPlayback;
    
    err = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(audioCategory), &audioCategory);
    
    if (err != noErr) {
        return [NSError errorWithDomain:@"Please verify that your device supports harware accelerated video encoding." code:1 userInfo:nil];
    }

    NSString *destination = [[source stringByDeletingPathExtension]stringByAppendingPathExtension:@"m4a"];
    
    UInt32 priorMixOverrideValue;
    
    UInt32 size;
    
    AudioSessionGetProperty(kAudioSessionProperty_OverrideCategoryMixWithOthers, &size, &priorMixOverrideValue);
    
    ExtAudioFileRef sourceFile;
    AudioStreamBasicDescription sourceFormat;
    
    if (source) {
        
        err = ExtAudioFileOpenURL((CFURLRef)[NSURL fileURLWithPath:source], &sourceFile);
        
        if (err != noErr) {
            if ([[NSFileManager defaultManager]fileExistsAtPath:destination]) {
                [[NSFileManager defaultManager]removeItemAtPath:destination error:nil];
            }
            return [NSError errorWithDomain:@"Failed to open audio file." code:1 userInfo:nil];
        }
        
        err = ExtAudioFileGetProperty(sourceFile, kExtAudioFileProperty_FileDataFormat, &size, &sourceFormat);

        if (err != noErr) {
            if ([[NSFileManager defaultManager]fileExistsAtPath:destination]) {
                [[NSFileManager defaultManager]removeItemAtPath:destination error:nil];
            }
            return [NSError errorWithDomain:@"Failed to get source information about audio file." code:1 userInfo:nil];
        }
        
        AudioStreamBasicDescription destinationFormat;
        
        memset(&destinationFormat, 0, sizeof(destinationFormat));
        destinationFormat.mChannelsPerFrame = sourceFormat.mChannelsPerFrame;
        destinationFormat.mFormatID = kAudioFormatMPEG4AAC;
        
        err = AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, nil, &size, &destinationFormat);
        
        if (err != noErr) {
            if ([[NSFileManager defaultManager]fileExistsAtPath:destination]) {
                [[NSFileManager defaultManager]removeItemAtPath:destination error:nil];
            }
            return [NSError errorWithDomain:@"Failed to setup destination format." code:1 userInfo:nil];
        }
        
        ExtAudioFileRef destinationFile;
        
        [[NSFileManager defaultManager]createFileAtPath:destination contents:nil attributes:nil];
        
        err = ExtAudioFileCreateWithURL((CFURLRef)[NSURL fileURLWithPath:destination], kAudioFileM4AType, &destinationFormat, NULL, kAudioFileFlags_EraseFile, &destinationFile);
        
        if (err != noErr) {
            if ([[NSFileManager defaultManager]fileExistsAtPath:destination]) {
                [[NSFileManager defaultManager]removeItemAtPath:destination error:nil];
            }
            return [NSError errorWithDomain:@"Couldn't open the source file." code:1 userInfo:nil];
        }

        AudioStreamBasicDescription clientFormat;
        if (sourceFormat.mFormatID == kAudioFormatLinearPCM) {
            clientFormat = sourceFormat;
        } else {
            memset(&clientFormat, 0, sizeof(clientFormat));
            int sampleSize = sizeof(AudioSampleType);
            clientFormat.mFormatID = kAudioFormatLinearPCM;
            clientFormat.mFormatFlags = kAudioFormatFlagsCanonical;
            clientFormat.mBitsPerChannel = 8 * sampleSize;
            clientFormat.mChannelsPerFrame = sourceFormat.mChannelsPerFrame;
            clientFormat.mFramesPerPacket = 1;
            clientFormat.mBytesPerPacket = clientFormat.mBytesPerFrame = sourceFormat.mChannelsPerFrame * sampleSize;
            clientFormat.mSampleRate = sourceFormat.mSampleRate;
        }
        
        size = sizeof(clientFormat);
        
        OSStatus err0 = ExtAudioFileSetProperty(sourceFile, kExtAudioFileProperty_ClientDataFormat, size, &clientFormat);
        OSStatus err1 = ExtAudioFileSetProperty(destinationFile, kExtAudioFileProperty_ClientDataFormat, size, &clientFormat);
        
        if ((sourceFile && err0) || err1) {
            if (sourceFile) {
                ExtAudioFileDispose(sourceFile);
            }
            
            ExtAudioFileDispose(destinationFile);
            
            if ([[NSFileManager defaultManager]fileExistsAtPath:destination]) {
                [[NSFileManager defaultManager]removeItemAtPath:destination error:nil];
            }
            
            return [NSError errorWithDomain:@"Couldn't setup intermediate conversion format." code:1 userInfo:nil];
        }
        

        AudioConverterRef converter;
        size = sizeof(converter);
        
        err = ExtAudioFileGetProperty(destinationFile, kExtAudioFileProperty_AudioConverter, &size, &converter);
        
        if (err != noErr) {
            if ([[NSFileManager defaultManager]fileExistsAtPath:destination]) {
                [[NSFileManager defaultManager]removeItemAtPath:destination error:nil];
            }
            return [NSError errorWithDomain:@"Failed to setup converter." code:1 userInfo:nil];
        }
        
        SInt64 lengthInFrames = 0;
        if (sourceFile) {
            size = sizeof(lengthInFrames);
            ExtAudioFileGetProperty(sourceFile, kExtAudioFileProperty_FileLengthFrames, &size, &lengthInFrames);
        }
        
        UInt32 bufferByteSize = 32768;
        char srcBuffer[bufferByteSize];
        SInt64 sourceFrameOffset = 0;
        BOOL reportProgress = lengthInFrames > 0;
        NSTimeInterval lastProgressReport = [NSDate timeIntervalSinceReferenceDate];
        
        while (YES) {
            AudioBufferList fillBufList;
            fillBufList.mNumberBuffers = 1;
            fillBufList.mBuffers[0].mNumberChannels = clientFormat.mChannelsPerFrame;
            fillBufList.mBuffers[0].mDataByteSize = bufferByteSize;
            fillBufList.mBuffers[0].mData = srcBuffer;
            
            UInt32 numFrames = bufferByteSize/clientFormat.mBytesPerFrame;
            
            if (sourceFile) {
                err = ExtAudioFileRead(sourceFile, &numFrames, &fillBufList);
                
                if (err != noErr) {
                    ExtAudioFileDispose(sourceFile);
                    ExtAudioFileDispose(destinationFile);
                    return [NSError errorWithDomain:@"Error reading the source file." code:1 userInfo:nil];
                }
            }
            
            if (!numFrames) {
                break;
            }
            
            sourceFrameOffset += numFrames;
            
            
            OSStatus status = ExtAudioFileWrite(destinationFile, numFrames, &fillBufList);
            
            if (status == kExtAudioFileError_CodecUnavailableInputNotConsumed) {
                sourceFrameOffset -= numFrames;
                if (sourceFile) {
                    ExtAudioFileSeek(sourceFile, sourceFrameOffset);
                }
            } else if (status != noErr) {
                if (sourceFile) {
                    ExtAudioFileDispose(sourceFile);
                }
                ExtAudioFileDispose(destinationFile);
            }
            
            if (reportProgress && [NSDate timeIntervalSinceReferenceDate]-lastProgressReport > 0.1) {
                lastProgressReport = [NSDate timeIntervalSinceReferenceDate];

                if ([progressObject respondsToSelector:@selector(setProgress:)]) {
                    [progressObject setProgress:(double)sourceFrameOffset/lengthInFrames];
                }
            }
        }
        
        if ([progressObject respondsToSelector:@selector(setProgress:)]) {
            [progressObject setProgress:1.0f];
        }
        
        if (sourceFile) {
            ExtAudioFileDispose(sourceFile);
        }
        ExtAudioFileDispose(destinationFile);
        
        
    } else {
        [[NSFileManager defaultManager]removeItemAtPath:destination error:nil];
        if (priorMixOverrideValue) {
            UInt32 allowMixing = priorMixOverrideValue;
            err = AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryMixWithOthers, sizeof(allowMixing), &allowMixing);
            if (err != noErr) {
                return [NSError errorWithDomain:@"Epic clusterfudge while trying to return the audio session to normal." code:1 userInfo:nil];
            }
        }
    }
    
    return nil;
}

@end
