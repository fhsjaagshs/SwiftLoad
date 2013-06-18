//
//  WhiteProgressView.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/18/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WhiteProgressView : UIView

@property (nonatomic, assign) float progress;
@property (nonatomic, assign) float isIndeterminate;

- (void)drawGreen;
- (void)drawRed;

@end
