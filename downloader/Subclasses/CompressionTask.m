//
//  CompressionTask.m
//  Swift
//
//  Created by Nathaniel Symer on 7/28/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "CompressionTask.h"

@interface CompressionTask ()

@property (nonatomic, strong) NSArray *itemsToCompress;
@property (nonatomic, strong) NSString *zipFileLocation;

@end

@implementation CompressionTask

+ (CompressionTask *)taskWithItems:(NSArray *)items andZipFile:(NSString *)zipFile {
    return [[[self class]alloc]initWithItems:items andZipFile:zipFile];
}

- (id)initWithItems:(NSArray *)items andZipFile:(NSString *)zipFile {
    self = [super init];
    if (self) {
        self.itemsToCompress = items;
        self.zipFileLocation = zipFile;
    }
    return self;
}

- (BOOL)canStop {
    return NO;
}

- (void)start {
    [super start];
    [self compress];
}

- (void)compress {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            for (NSString *theFile in _itemsToCompress) {
                NSString *currentDir = [kAppDelegate managerCurrentDir];
                
                BOOL isDirMe;
                [[NSFileManager defaultManager]fileExistsAtPath:theFile isDirectory:&isDirMe];

                ZipFile *zipFile = [[ZipFile alloc]initWithFileName:_zipFileLocation mode:(fileSize(_zipFileLocation) == 0)?ZipFileModeCreate:ZipFileModeAppend];
                
                if (!isDirMe) {
                    ZipWriteStream *stream1 = [zipFile writeFileInZipWithName:[theFile lastPathComponent] fileDate:fileDate(theFile) compressionLevel:ZipCompressionLevelBest];
                    
                    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:theFile];
                    
                    do {
                        int fsZ = fileSize(theFile);
                        int readLength = 1024*1024;
                        if (fsZ < readLength) {
                            readLength = fsZ;
                        }
                        NSData *readData = [fileHandle readDataOfLength:readLength];
                        if (readData.length == 0) {
                            break;
                        } else {
                            [stream1 writeData:readData];
                        }
                    } while (YES);
                    
                    [fileHandle closeFile];
                    
                    [stream1 finishedWriting];
                } else {
                    
                    NSString *origDir = [theFile lastPathComponent];
                    NSString *dash = [origDir substringFromIndex:origDir.length-1];
                    
                    if (![dash isEqualToString:@"/"]) {
                        origDir = [origDir stringByAppendingString:@"/"];
                    }
                    
                    ZipWriteStream *stream1 = [zipFile writeFileInZipWithName:origDir fileDate:fileDate(theFile) compressionLevel:ZipCompressionLevelBest];
                    
                    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:theFile];
                    
                    do {
                        NSData *readData = [fileHandle readDataOfLength:1024*1024];
                        if (readData.length == 0) {
                            break;
                        } else {
                            [stream1 writeData:readData];
                        }
                    } while (YES);
                    
                    [fileHandle closeFile];
                    
                    [stream1 finishedWriting];
                    
                    
                    NSArray *array = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:theFile error:nil]; // a directory being added to a zip
                    
                    NSMutableArray *dirsInDir = [[NSMutableArray alloc]init];
                    
                    for (NSString *filename in array) {
                        NSString *thing = [theFile stringByAppendingPathComponent:filename];
                        
                        BOOL shouldBeADir;
                        BOOL shouldBeADirOne = [[NSFileManager defaultManager]fileExistsAtPath:thing isDirectory:&shouldBeADir];
                        
                        if (shouldBeADir && shouldBeADirOne) {
                            [dirsInDir addObject:thing];
                        } else if (shouldBeADirOne) {
                            NSString *finalFN = [[theFile lastPathComponent]stringByAppendingPathComponent:filename];
                            ZipWriteStream *stream1 = [zipFile writeFileInZipWithName:finalFN fileDate:[NSDate dateWithTimeIntervalSinceNow:-86400.0] compressionLevel:ZipCompressionLevelBest];
                            
                            NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:thing];
                            
                            do {
                                int fsZ = fileSize(thing);
                                int readLength = 1024*1024;
                                if (fsZ < readLength) {
                                    readLength = fsZ;
                                }
                                NSData *readData = [fileHandle readDataOfLength:readLength];
                                if (readData.length == 0) {
                                    break;
                                } else {
                                    [stream1 writeData:readData];
                                }
                            } while (YES);
                            
                            [fileHandle closeFile];
                            
                            [stream1 finishedWriting];
                        }
                    }
                    
                    NSMutableArray *holdingArray = [[NSMutableArray alloc]init];
                    
                    do {
                        for (NSString *dir in dirsInDir) {
                            
                            NSString *dirRelative = [dir stringByReplacingOccurrencesOfString:[currentDir stringByAppendingString:@"/"]withString:@""]; // gets current directory in zip
                            
                            NSString *asdfasdf = [dirRelative substringFromIndex:[dirRelative length]-1];
                            
                            if (![asdfasdf isEqualToString:@"/"]) {
                                dirRelative = [dirRelative stringByAppendingString:@"/"];
                            }
                            
                            ZipWriteStream *stream1 = [zipFile writeFileInZipWithName:dirRelative fileDate:fileDate(dir) compressionLevel:ZipCompressionLevelBest];
                            [stream1 writeData:[NSData dataWithContentsOfFile:dir]]; // okay not to chunk
                            [stream1 finishedWriting];
                            
                            NSArray *arrayZ = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:dir error:nil];
                            
                            for (NSString *stringy in arrayZ) {
                                
                                NSString *lolz = [dir stringByAppendingPathComponent:stringy]; // stringy used to be dir
                                
                                BOOL dirIsMe;
                                [[NSFileManager defaultManager]fileExistsAtPath:lolz isDirectory:&dirIsMe];
                                
                                if (dirIsMe) {
                                    [holdingArray addObject:lolz];
                                } else {
                                    NSString *nameOfFile = [dirRelative stringByAppendingPathComponent:stringy];
                                    ZipWriteStream *stream1 = [zipFile writeFileInZipWithName:nameOfFile fileDate:fileDate(lolz) compressionLevel:ZipCompressionLevelBest];
                                    
                                    [[[NSFileManager defaultManager]attributesOfFileSystemForPath:lolz error:nil]fileCreationDate];
                                    
                                    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:lolz];
                                    
                                    do {
                                        NSData *readData = [fileHandle readDataOfLength:1024*1024];
                                        if (readData.length == 0) {
                                            break;
                                        } else {
                                            [stream1 writeData:readData];
                                        }
                                    } while (YES);
                                    
                                    [fileHandle closeFile];
                                    
                                    [stream1 finishedWriting];
                                }
                            }
                        }
                        
                        if (holdingArray.count == 0) {
                            break;
                        } else {
                            [dirsInDir removeAllObjects];
                            [dirsInDir addObjectsFromArray:holdingArray];
                            [holdingArray removeAllObjects];
                        }
                        
                    } while (YES);
                }
                
                [zipFile close];
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    @autoreleasepool {
                        [self showSuccess];
                    }
                });
            }
        }
    });
}

@end
