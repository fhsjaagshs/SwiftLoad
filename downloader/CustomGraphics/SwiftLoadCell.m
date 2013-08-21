//
//  CustomCellCell.m
//  Test
//
//  Created by Nathaniel Symer on 5/20/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "SwiftLoadCell.h"

@interface SwiftLoadCell ()

@end

@implementation SwiftLoadCell

- (void)hideImageView:(BOOL)shouldHide {
    [UIView animateWithDuration:0.5f animations:^{
        self.imageView.hidden = shouldHide;
    }];
}

- (void)layoutSubviews {
    
    if (self.imageView.hidden) {
        UIImage *image = self.imageView.image;
        self.imageView.image = nil;
        
        [super layoutSubviews];
        
        self.imageView.image = image;
        return;
    }
    
    [super layoutSubviews];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.textLabel.highlightedTextColor = [UIColor blackColor];
        self.detailTextLabel.backgroundColor = [UIColor clearColor];
        self.detailTextLabel.highlightedTextColor = [UIColor blackColor];
        self.selectedBackgroundView = [[UIView alloc]init];
        self.selectedBackgroundView.backgroundColor = [UIColor colorWithWhite:208.0/255.0 alpha:1.0];
        self.detailTextLabel.textColor = [UIColor colorWithWhite:85.0/255.0 alpha:1.0];
        self.accessoryView.backgroundColor = [UIColor clearColor];
        self.multipleSelectionBackgroundView = [[UIView alloc]init];
        self.multipleSelectionBackgroundView.backgroundColor = [UIColor clearColor];
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            //self.textLabel.font = [UIFont fontWithName:@"MarkerFelt-Thin" size:27];
            self.textLabel.font = [UIFont fontWithName:@"Avenir-Medium" size:24];
            self.detailTextLabel.font = [UIFont systemFontOfSize:20.0];
        } else {
            //self.textLabel.font = [UIFont fontWithName:@"MarkerFelt-Thin" size:20];
            self.textLabel.font = [UIFont fontWithName:@"Avenir-Medium" size:17];
        }
        
        self.textLabel.lineBreakMode = UILineBreakModeTailTruncation;
        self.detailTextLabel.textColor = [UIColor colorWithWhite:0.5f alpha:1.0f];
        
        self.isFirstCell = NO;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSaveGState(context);
    
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextFillRect(context, self.bounds);
    
    if (!_isFirstCell) {
        CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:208.0/255.0 alpha:1.0].CGColor);
        CGContextSetLineWidth(context, 2.0);
        CGContextSetLineCap(context, kCGLineCapRound);
        
        CGPoint points[] = { CGPointMake(50, self.bounds.origin.y-0.5), CGPointMake(self.bounds.size.width-50, self.bounds.origin.y-0.5) };
        CGContextStrokeLineSegments(context, points, 2);
    }
    
    CGContextRestoreGState(context);
}

@end
