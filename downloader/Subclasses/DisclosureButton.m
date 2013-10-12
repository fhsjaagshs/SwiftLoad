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
