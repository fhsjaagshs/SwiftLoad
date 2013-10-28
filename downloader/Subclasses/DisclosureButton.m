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
    [[UIImage imageNamed:self.highlighted?@"disclosure_highlighted":@"disclosure"]drawInRect:CGRectMake((rowHeight-11)/2, (rowHeight-11)/2, 11, 11)];
}

+ (DisclosureButton *)button {
    return [[[self class]alloc]initWithFrame:CGRectMake(0, 0, 44, 44)];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
    }
    return self;
}

- (void)setHighlighted:(BOOL)highlighted {
	[super setHighlighted:highlighted];
	[self setNeedsDisplay];
}

@end
