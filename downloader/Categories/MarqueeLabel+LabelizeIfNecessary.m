//
//  MarqueeLabel+LabelizeIfNecessary.m
//  Swift
//
//  Created by Nathaniel Symer on 8/7/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "MarqueeLabel+LabelizeIfNecessary.h"

@implementation MarqueeLabel (LabelizeIfNecessary)

- (void)labelizeIfNecessary {
    float width = [self.text widthForHeight:self.bounds.size.height font:self.font];
    self.labelize = (width < self.frame.size.width-5);
}

@end
