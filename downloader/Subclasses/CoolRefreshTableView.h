//
//  CoolRefreshTableView.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/18/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "ShadowedTableView.h"

typedef enum {
    CoolRefreshAnimationStyleBackward,
    CoolRefreshAnimationStyleForward,
    CoolRefreshAnimationStyleNone
} CoolRefreshAnimationStyle;

@interface CoolRefreshTableView : ShadowedTableView

- (void)reloadDataWithCoolAnimationType:(CoolRefreshAnimationStyle)style;

@end
