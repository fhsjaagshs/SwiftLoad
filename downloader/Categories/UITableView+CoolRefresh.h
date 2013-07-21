//
//  UITableView+CoolRefresh.h
//  Swift
//
//  Created by Nathaniel Symer on 7/20/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    CoolRefreshAnimationStyleBackward,
    CoolRefreshAnimationStyleForward,
    CoolRefreshAnimationStyleNone
} CoolRefreshAnimationStyle;

@interface UITableView (CoolRefresh)

- (void)reloadDataWithCoolAnimationType:(CoolRefreshAnimationStyle)style;

@end
