//
//  AudioConverter.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 12/8/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AudioConverter : NSObject

+ (NSError *)convertAudioFileAtPath:(NSString *)source progressObject:(id)progressObject;

@end
