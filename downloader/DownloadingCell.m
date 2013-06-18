//
//  DownloadingCell.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/18/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "DownloadingCell.h"

@interface DownloadingCell ()

@property (nonatomic, retain) WhiteProgressView *progressView;

@end

@implementation DownloadingCell

- (void)setProgress:(float)progress {
    _progress = progress;
    _progressView.progress = progress;
}

- (id)initWithResuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        self.progressView = [[[WhiteProgressView alloc]initWithFrame:CGRectMake(10, 5, self.frame.size.width-20, 20)]autorelease];
        self.titleLabel = [[[UILabel alloc]initWithFrame:CGRectMake(0, 25, self.frame.size.width, 20)]autorelease];
        _titleLabel.tag = 69;
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textAlignment = UITextAlignmentCenter;
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont boldSystemFontOfSize:12];
        
        [self.contentView addSubview:_titleLabel];
        [self.contentView addSubview:_progressView];
        
        self.contentView.backgroundColor = [UIColor clearColor];
        self.backgroundView.backgroundColor = [UIColor clearColor];
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    Class UILabel = [UILabel class];
    
    for (UIView *view in self.subviews) {
        if ([view isKindOfClass:UILabel] && view.tag != 69) {
            [view removeFromSuperview];
        }
    }
}

@end
