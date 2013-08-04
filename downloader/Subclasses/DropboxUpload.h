//
//  DropboxUpload.h
//  Swift
//
//  Created by Nathaniel Symer on 8/3/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DropboxUpload : Upload

+ (DropboxUpload *)uploadWithFile:(NSString *)file;

@end
