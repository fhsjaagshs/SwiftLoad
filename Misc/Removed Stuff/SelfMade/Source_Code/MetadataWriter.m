//
//  MetadataWriter.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 12/2/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "MetadataWriter.h"

#include "tag.h"

@implementation MetadataWriter

+ (void)messupID3:(NSString *)path {
    // Read title tag
    ID3_Tag tag;
    tag.Link([path UTF8String]);
    
    ID3_Frame *titleFrame = tag.Find(ID3FID_TITLE);
    unicode_t const *value = titleFrame->GetField(ID3FN_TEXT)->GetRawUnicodeText();
    NSString *title = [NSString stringWithCString:(char const *) value encoding:NSUnicodeStringEncoding];
    NSLog(@"The title before is %@", title);
    
    
    // Write title tag
    tag.Link([docPath UTF8String]);
    tag.Strip(ID3TT_ALL);
    tag.Clear();
    
    ID3_Frame frame;
    frame.SetID(ID3FID_TITLE);
    frame.GetField(ID3FN_TEXTENC)->Set(ID3TE_UNICODE);
    NSString *newTitle = [title stringByAppendingString:@"_fucker"];
    frame.GetField(ID3FN_TEXT)->Set((unicode_t *) [newTitle cStringUsingEncoding:NSUTF16StringEncoding]);
    
    tag.AddFrame(frame);
    
    tag.SetPadding(false);
    tag.SetUnsync(false);
    tag.Update(ID3TT_ID3V2);
    
    NSLog(@"The title after is %@", newTitle);
}


@end
