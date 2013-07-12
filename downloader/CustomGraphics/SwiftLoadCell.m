//
//  CustomCellCell.m
//  Test
//
//  Created by Nathaniel Symer on 5/20/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "SwiftLoadCell.h"

@implementation SwiftLoadCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.textLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        self.textLabel.highlightedTextColor = [UIColor blackColor];
        self.detailTextLabel.backgroundColor = [UIColor clearColor];    
        self.detailTextLabel.highlightedTextColor = [UIColor blackColor];
        self.selectedBackgroundView = [[[UIView alloc]init]autorelease];
        self.selectedBackgroundView.backgroundColor = [UIColor colorWithWhite:208.0/255.0 alpha:1.0];
        self.detailTextLabel.textColor = [UIColor colorWithWhite:85.0/255.0 alpha:1.0];
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            self.textLabel.font = [UIFont fontWithName:@"MarkerFelt-Thin" size:27];
            self.detailTextLabel.font = [UIFont systemFontOfSize:20.0];
        } else {
            self.textLabel.font = [UIFont fontWithName:@"MarkerFelt-Thin" size:20];
        }
    }
    return self;
}


- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGColorRef whiteColor = [UIColor whiteColor].CGColor;
    CGColorRef separatorColor = [UIColor colorWithWhite:208.0/255.0 alpha:1.0].CGColor;
    CGContextSaveGState(context);
    
    CGContextSetFillColorWithColor(context, whiteColor);
    CGContextFillRect(context, self.bounds);
    
    CGContextRestoreGState(context);
    
    CGRect strokeRect = self.bounds;
    strokeRect.size.height -= 1;
    strokeRect = CGRectMake(strokeRect.origin.x+0.5, strokeRect.origin.y+0.5, strokeRect.size.width-1, strokeRect.size.height-1);
        
    CGContextSetStrokeColorWithColor(context, whiteColor);
    CGContextSetLineWidth(context, 1.0);
    CGContextStrokeRect(context, strokeRect);
    
    CGPoint startPoint = CGPointMake(self.bounds.origin.x, self.bounds.origin.y+self.bounds.size.height-1);
    CGPoint endPoint = CGPointMake(self.bounds.origin.x+self.bounds.size.width-1, self.bounds.origin.y+self.bounds.size.height-1);
    
    CGContextSaveGState(context);
    CGContextSetLineCap(context, kCGLineCapSquare);
    CGContextSetStrokeColorWithColor(context, separatorColor);
    CGContextSetLineWidth(context, 1.0);
    CGContextMoveToPoint(context, startPoint.x + 0.5, startPoint.y + 0.5);
    CGContextAddLineToPoint(context, endPoint.x + 0.5, endPoint.y + 0.5);
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
}

@end
