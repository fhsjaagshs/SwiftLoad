//
//  TaskCell.m
//  Swift
//
//  Created by Nathaniel Symer on 7/28/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "TaskCell.h"

@interface TaskCell ()

@property (nonatomic, strong) CircularProgressView *progressView;

@end

@implementation TaskCell

- (void)setText:(NSString *)text {
    self.textLabel.text = text;
}

- (void)setDetailText:(NSString *)string {
    self.detailTextLabel.text = string;
}

- (void)reset {
    self.progress = 0.0f;
    [_progressView reset];
}

- (void)drawGreen {
    [_progressView drawGreen];
}

- (void)drawRed {
    [_progressView drawRed];
}

- (void)setProgress:(float)progress {
    _progress = progress;
    _progressView.progress = progress;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    float maxWidth = self.bounds.size.width-49;
    
    CGRect text = self.textLabel.frame;
    text.origin.x = 49;

    if (text.size.width > maxWidth) {
        text.size.width = maxWidth;
    }
    
    self.textLabel.frame = text;
    
    CGRect detail = self.detailTextLabel.frame;
    detail.origin.x = 49;
    
    if (detail.size.width > maxWidth) {
        detail.size.width = maxWidth;
    }
    
    self.detailTextLabel.frame = detail;
    
    _progressView.frame = CGRectMake(5, 5, 37, 37);
}

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        self.textLabel.textColor = [UIColor blackColor];
        self.detailTextLabel.textColor = [UIColor darkGrayColor];
        
        self.progressView = [[CircularProgressView alloc]initWithFrame:CGRectZero];
        [self addSubview:_progressView];
        
        self.contentView.backgroundColor = [UIColor clearColor];
        self.backgroundColor = [UIColor clearColor];
        
        self.textLabel.highlightedTextColor = [UIColor blackColor];
        self.textLabel.textAlignment = NSTextAlignmentLeft;
        self.selectedBackgroundView = [[UIView alloc]init];
        self.selectedBackgroundView.backgroundColor = [UIColor lightGrayColor];
    }
    return self;
}

@end
