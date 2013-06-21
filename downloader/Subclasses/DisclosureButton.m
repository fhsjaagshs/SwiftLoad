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
    if (self.highlighted) {
        [[UIImage imageNamed:@"arrow_disclosure_highlighted"]drawInRect:CGRectMake(11, 11, 22, 22)];
    } else {
        [[UIImage imageNamed:@"arrow_disclosure"]drawInRect:CGRectMake(11, 11, 22, 22)];
    }
}

+ (DisclosureButton *)button {
    DisclosureButton *ret = [[[[self class]alloc]initWithFrame:CGRectMake(0, 0, 44, 44)]autorelease];
    ret.backgroundColor = [UIColor clearColor];
    return ret;
}

- (void)setHighlighted:(BOOL)highlighted {
	[super setHighlighted:highlighted];
	[self setNeedsDisplay];
}

@end
