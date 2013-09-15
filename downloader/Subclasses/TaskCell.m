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

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        self.textLabel.textColor = [UIColor blackColor];
        self.detailTextLabel.textColor = [UIColor darkGrayColor];
        
        self.progressView = [[CircularProgressView alloc]initWithFrame:CGRectMake(5, 5, 37, 37)];
        self.accessoryView = _progressView;
        
        self.textLabel.backgroundColor = [UIColor whiteColor];
        self.textLabel.highlightedTextColor = [UIColor blackColor];
        self.textLabel.textAlignment = NSTextAlignmentCenter;
        self.selectedBackgroundView = [[UIView alloc]init];
        self.selectedBackgroundView.backgroundColor = [UIColor lightGrayColor];
        self.opaque = YES;
    }
    return self;
}

@end
