//
//  CustomCellCell.h
//  Test
//
//  Created by Nathaniel Symer on 5/20/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SwiftLoadCell : UITableViewCell

@property (nonatomic, assign) BOOL isFirstCell;

- (void)hideImageView:(BOOL)shouldHide;

@end
