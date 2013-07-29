//
//  AudioConversionTask.h
//  Swift
//
//  Created by Nathaniel Symer on 7/29/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "Task.h"

@interface AudioConversionTask : Task

+ (AudioConversionTask *)taskWithSourceAudioFile:(NSString *)source;

@end
