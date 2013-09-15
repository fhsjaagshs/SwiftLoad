//
//  PeerPickerCell.m
//  Swift
//
//  Created by Nathaniel Symer on 7/16/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "PeerPickerCell.h"

@implementation PeerPickerCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.textLabel.highlightedTextColor = [UIColor blackColor];
        self.textLabel.textAlignment = NSTextAlignmentCenter;
        self.selectedBackgroundView = [[UIView alloc]init];
        self.selectedBackgroundView.backgroundColor = [UIColor lightGrayColor];
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
