//
//  DownloadingCell.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/18/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "DownloadingCell.h"

@interface DownloadingCell ()

@property (nonatomic, strong) WhiteProgressView *progressView;

@end

@implementation DownloadingCell



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
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        self.progressView = [[WhiteProgressView alloc]init];
        self.customTitleLabel = [[UILabel alloc]init];
        _customTitleLabel.tag = 69;
        _customTitleLabel.backgroundColor = [UIColor clearColor];
        _customTitleLabel.textAlignment = UITextAlignmentCenter;
        _customTitleLabel.textColor = [UIColor whiteColor];
        _customTitleLabel.font = [UIFont boldSystemFontOfSize:12];
        
        [self.contentView addSubview:_customTitleLabel];
        [self.contentView addSubview:_progressView];
        
        self.contentView.backgroundColor = [UIColor clearColor];
        self.backgroundView.backgroundColor = [UIColor clearColor];
        self.backgroundColor = [UIColor clearColor];
        self.textLabel.textColor = [UIColor clearColor];
        self.textLabel.userInteractionEnabled = NO;
        [self.textLabel removeFromSuperview];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.detailTextLabel removeFromSuperview];
    _progressView.frame = CGRectMake(5, 5, self.bounds.size.width-20, 20);
    _customTitleLabel.frame = CGRectMake(0, 25, self.bounds.size.width, 20);
    [_progressView setNeedsDisplay];
}

@end
