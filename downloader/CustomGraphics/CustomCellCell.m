//
//  CustomCellCell.m
//  Test
//
//  Created by Nathaniel Symer on 5/20/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "CustomCellCell.h"
#import "Common.h"

@implementation CustomCellCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.textLabel.backgroundColor = [UIColor clearColor];    
        self.textLabel.highlightedTextColor = [UIColor blackColor];
        self.detailTextLabel.backgroundColor = [UIColor clearColor];    
        self.detailTextLabel.highlightedTextColor = [UIColor blackColor];
        self.selectionStyle = UITableViewCellSelectionStyleGray;
        self.detailTextLabel.textColor = [UIColor blackColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGColorRef whiteColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0].CGColor; 
    CGColorRef lightGrayColor = [UIColor colorWithRed:230.0/255.0 green:230.0/255.0 blue:230.0/255.0 alpha:1.0].CGColor;
    CGColorRef separatorColor = [UIColor colorWithRed:208.0/255.0 green:208.0/255.0 blue:208.0/255.0 alpha:1.0].CGColor;
    
    // Fill with gradient
    if (self.selected) {
        drawLinearGradient(context, self.bounds, lightGrayColor, separatorColor);
    } else {
        drawLinearGradient(context, self.bounds, whiteColor, lightGrayColor);
    }
    
    // Add white 1 px stroke
    CGRect strokeRect = self.bounds;
    strokeRect.size.height -= 1;
    strokeRect = rectFor1PxStroke(strokeRect);
        
    CGContextSetStrokeColorWithColor(context, whiteColor);
    CGContextSetLineWidth(context, 1.0);
    CGContextStrokeRect(context, strokeRect);
        
    // Add separator
    CGPoint startPoint = CGPointMake(self.bounds.origin.x, self.bounds.origin.y+self.bounds.size.height-1);
    CGPoint endPoint = CGPointMake(self.bounds.origin.x+self.bounds.size.width-1, self.bounds.origin.y+self.bounds.size.height-1);
    draw1PxStroke(context, startPoint, endPoint, separatorColor); 
}

@end
