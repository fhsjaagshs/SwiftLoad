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
    [self setProgress:0.0f];
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

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        self.textLabel.textColor = [UIColor blackColor];
        self.detailTextLabel.textColor = [UIColor darkGrayColor];
        
        self.progressView = [[CircularProgressView alloc]initWithFrame:CGRectMake(2, 2, 40, 40)];
        self.accessoryView = _progressView;
        
        self.contentView.backgroundColor = [UIColor clearColor];
        self.backgroundView.backgroundColor = [UIColor clearColor];
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

@end
