//
//  HamburgerCell.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 7/13/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "HamburgerCell.h"



@implementation HamburgerCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.textLabel.backgroundColor = bgcolor;
        self.textLabel.highlightedTextColor = [UIColor blackColor];
        self.textLabel.textAlignment = UITextAlignmentCenter;
        self.selectedBackgroundView = [[UIView alloc]init];
        self.selectedBackgroundView.backgroundColor = [UIColor lightGrayColor];
        self.opaque = YES;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    if (!_isFirstCell) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGContextSaveGState(context);
        
        CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:187.0/255.0 alpha:1.0].CGColor);
        CGContextSetLineWidth(context, 2.0);
        CGContextSetLineCap(context, kCGLineCapRound);
        
        CGPoint points[] = { CGPointMake(50, self.bounds.origin.y-0.5), CGPointMake(self.bounds.size.width-50, self.bounds.origin.y-0.5) };
        CGContextStrokeLineSegments(context, points, 2);
        
        CGContextRestoreGState(context);
    }
}

@end
