//
//  Download.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/17/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Download : NSObject

@property (nonatomic, assign) float fileSize;
@property (nonatomic, strong) NSString *fileName;

@end
