//
//  CustomCellCell.m
//  Test
//
//  Created by Nathaniel Symer on 5/20/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "SwiftLoadCell.h"

static NSString * const kFontName = @"Avenir-Medium";

@interface SwiftLoadCell ()

@end

@implementation SwiftLoadCell

- (void)enterEditMode {
    [self setEditing:YES animated:YES];
}

- (void)exitEditMode {
    [self setEditing:NO animated:YES];
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
        self.textLabel.font = [UIFont fontWithName:kFontName size:17];
        self.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.detailTextLabel.textColor = [UIColor colorWithWhite:0.5f alpha:1.0f];
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

@end
