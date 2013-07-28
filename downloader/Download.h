//
//  Download.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/17/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DownloadingCell;

@interface Download : Task

//@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, strong) NSString *temporaryPath;

@end