//
//  DisclosureButton.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/20/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "DisclosureButton.h"

@implementation DisclosureButton

- (void)drawRect:(CGRect)rect {
    int rowHeight = self.bounds.size.height;
    [[UIImage imageNamed:self.highlighted?@"arrow_disclosure_highlighted":@"arrow_disclosure"]drawInRect:CGRectMake(rowHeight/4, rowHeight/4, rowHeight/2, rowHeight/2)];
}

+ (DisclosureButton *)button {
    DisclosureButton *ret = [[[self class]alloc]initWithFrame:CGRectMake(0, 0, 44, 44)];
    ret.backgroundColor = [UIColor clearColor];
    return ret;
}

- (void)setHighlighted:(BOOL)highlighted {
	[super setHighlighted:highlighted];
	[self setNeedsDisplay];
}

@end
