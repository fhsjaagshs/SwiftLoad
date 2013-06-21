//
//  DisclosureButton.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/20/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "DisclosureButton.h"

@implementation DisclosureButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

+ (DisclosureButton *)button {
    return [[[[self class]alloc]initWithFrame:CGRectMake(0, 0, 44, 44)]autorelease];
}

- (void)setHighlighted:(BOOL)highlighted {
	[super setHighlighted:highlighted];
	[self setNeedsDisplay];
}

@end
