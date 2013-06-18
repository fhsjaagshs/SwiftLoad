//
//  DownloadingCell.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/18/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DownloadingCell : UITableViewCell

- (void)drawGreen;
- (void)drawRed;

@property (nonatomic, assign, setter = setProgress:) float progress;
@property (nonatomic, retain) UILabel *titleLabel;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;

@end
