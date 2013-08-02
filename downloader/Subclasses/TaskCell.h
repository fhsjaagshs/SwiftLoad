//
//  TaskCell.h
//  Swift
//
//  Created by Nathaniel Symer on 7/28/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TaskCell : UITableViewCell <TaskDelegate>

@property (nonatomic, assign, setter = setProgress:) float progress;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;

@end
