//
//  CustomSegmentedControl.h
//  SwiftLoad
//
//  Created by Nate Symer on 5/22/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomSegmentedControl : UISegmentedControl 

- (void)segmentChanged;
- (id)initWithItems:(NSArray *)items andFrame:(CGRect)frame;

@end
