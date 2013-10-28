//
//  Hamburger.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 7/13/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "HamburgerView.h"

static NSString * const kHamburgerTableUpdateNotification = @"kHamburgerTableUpdateNotification";

NSString * const kHamburgerNowPlayingUpdateNotification = @"kHamburgerNowPlayingUpdateNotification";
static NSString *kCellIdentifierHamburger = @"hamburgertext";
static NSString * const kCellIdentifierHamburgerSeparator = @"hamburgersep";
static NSString * const kCellIdentifierHamburgerTask = @"hamburgertask";

@interface HamburgerView () <UITableViewDataSource, UITableViewDelegate>

+ (HamburgerView *)view;

@property (nonatomic, strong) UITableView *theTableView;

@property (nonatomic, strong) UIButton *hideButton;
@property (nonatomic, weak) UIView *viewToMove;
@property (nonatomic, assign) BOOL originalOpacity;

@end

@implementation HamburgerView

+ (HamburgerView *)shared {
    static HamburgerView *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[HamburgerView alloc]init];
    });
    return shared;
}

+ (void)reloadCells {
    [[NSNotificationCenter defaultCenter]postNotificationName:kHamburgerTableUpdateNotification object:nil];
}

+ (HamburgerView *)view {
    return [[[self class]alloc]init];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.userInteractionEnabled = YES;
        self.backgroundColor = [UIColor whiteColor];
        self.alpha = 0.0f;
        self.frame = CGRectMake(0, 0, 250, [[UIScreen mainScreen]bounds].size.height);
        self.theTableView = [[UITableView alloc]initWithFrame:self.bounds style:UITableViewStylePlain];
        _theTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _theTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _theTableView.backgroundColor = [UIColor clearColor];
        _theTableView.rowHeight = 44;
        _theTableView.dataSource = self;
        _theTableView.delegate = self;
        _theTableView.separatorInset = UIEdgeInsetsMake(0, 50, 0, 0);
        [self addSubview:_theTableView];
        
        self.hideButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_hideButton addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchDown];
        
        [[NSNotificationCenter defaultCenter]addObserver:_theTableView selector:@selector(reloadData) name:kHamburgerTableUpdateNotification object:nil];
    }
    return self;
}

- (BOOL)hamburgerViewVisible {
    return self.superview != nil;
}

- (void)flashFromView:(UIView *)view {
    if (!self.hamburgerViewVisible) {
        [[[UIApplication sharedApplication]appWindow] insertSubview:self belowSubview:view];
        [[UIApplication sharedApplication]appWindow].userInteractionEnabled = NO;
        self.alpha = 1.0f;
        [self setNeedsDisplay];
        [UIView animateWithDuration:0.3f animations:^{
            view.frame = CGRectMake(150, view.frame.origin.y, view.frame.size.width, view.frame.size.height);
            [(UIView *)[[UIApplication sharedApplication]valueForKey:@"statusBar"] setTransform:CGAffineTransformMakeTranslation(150, 0)];
        } completion:^(BOOL finished) {
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                @autoreleasepool {
                    [NSThread sleepForTimeInterval:0.3f];
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        @autoreleasepool {
                            [UIView animateWithDuration:0.3f animations:^{
                                view.frame = CGRectMake(0, view.frame.origin.y, view.frame.size.width, view.frame.size.height);
                                [(UIView *)[[UIApplication sharedApplication]valueForKey:@"statusBar"] setTransform:CGAffineTransformIdentity];
                            } completion:^(BOOL finished) {
                                self.alpha = 0.0f;
                                [self removeFromSuperview];
                                [self setNeedsDisplay];
                                [[UIApplication sharedApplication]appWindow].userInteractionEnabled = YES;
                            }];
                        }
                    });
                }
            });
        }];
    }
}

- (void)hide {
    [UIView animateWithDuration:0.3f animations:^{
        self.alpha = 0.0f;
        _viewToMove.frame = CGRectMake(0, _viewToMove.frame.origin.y, _viewToMove.frame.size.width, _viewToMove.frame.size.height);
        [(UIView *)[[UIApplication sharedApplication]valueForKey:@"statusBar"] setTransform:CGAffineTransformIdentity];
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        [_hideButton removeFromSuperview];
        self.viewToMove = nil;
    }];
}

- (void)showFromView:(UIView *)view {
    self.viewToMove = view;
    _hideButton.frame = _viewToMove.bounds;
    [self setNeedsLayout];
    
    [[[UIApplication sharedApplication]appWindow] insertSubview:self belowSubview:_viewToMove];
    [_viewToMove addSubview:_hideButton];
    [UIView animateWithDuration:0.3f animations:^{
        self.alpha = 1.0f;
        _viewToMove.frame = CGRectMake(250, _viewToMove.frame.origin.y, _viewToMove.frame.size.width, _viewToMove.frame.size.height);
        [(UIView *)[[UIApplication sharedApplication]valueForKey:@"statusBar"] setTransform:CGAffineTransformMakeTranslation(250, 0)];
    } completion:^(BOOL finished) {
        [self setNeedsDisplay];
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (section == 0)?(kAppDelegate.nowPlayingFile != nil)?5:4:[[TaskController sharedController]numberOfTasks];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return ([[TaskController sharedController]numberOfTasks] > 0)?2:1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifierHamburger];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kCellIdentifierHamburger];
            cell.textLabel.backgroundColor = [UIColor whiteColor];
            cell.textLabel.highlightedTextColor = [UIColor blackColor];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.font = [UIFont fontWithName:@"Avenir-Medium" size:16];
            cell.selectedBackgroundView = [[UIView alloc]init];
            cell.selectedBackgroundView.backgroundColor = [UIColor lightGrayColor];
            cell.backgroundColor = [UIColor clearColor];
        }
        
        cell.detailTextLabel.text = nil;
        
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Download URL";
        } else if (indexPath.row == 1) {
            cell.textLabel.text = @"WebDAV Server";
        } else if (indexPath.row == 2) {
            cell.textLabel.text = @"Browse Dropbox";
        } else if (indexPath.row == 3) {
            cell.textLabel.text = @"Settings";
        } else if (indexPath.row == 4) {
            cell.textLabel.text = @"Now Playing";
            cell.detailTextLabel.text = [[MPNowPlayingInfoCenter defaultCenter]nowPlayingInfo][MPMediaItemPropertyTitle];
        }
        
        return cell;
    } else if (indexPath.section == 1) {
        TaskCell *cell = (TaskCell *)[_theTableView dequeueReusableCellWithIdentifier:kCellIdentifierHamburgerTask];
        
        if (!cell) {
            cell = [[TaskCell alloc]initWithReuseIdentifier:kCellIdentifierHamburgerTask];
        }
        
        Task *task = [[TaskController sharedController]taskAtIndex:(int)indexPath.row];
        task.delegate = cell;
        [cell setText:[task.name percentSanitize]];
        [cell setDetailText:[task verb]];
        [cell setSelectionStyle:[[[TaskController sharedController]taskAtIndex:(int)indexPath.row]canSelect]?UITableViewCellSelectionStyleGray:UITableViewCellSelectionStyleNone];
        
        return cell;
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        return ([[TaskController sharedController]numberOfTasks] > 0)?10:0;
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 1 && [[TaskController sharedController]numberOfTasks] > 0) {
        DashedLineView *dashedLineView = [[DashedLineView alloc]initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 5)];
        return dashedLineView;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        if ([[TaskController sharedController]numberOfTasks] > 0) {
            Task *task = [[TaskController sharedController]taskAtIndex:(int)indexPath.row];
            
            if ([task isKindOfClass:[HTTPDownload class]]) {
                [(HTTPDownload *)task resumeFromFailureIfNecessary];
            }
        }
    } else if (indexPath.section == 0) {
        if (_delegate && [_delegate respondsToSelector:@selector(hamburgerCellWasSelectedAtIndex:)]) {
            [self hide];
            [_delegate hamburgerCellWasSelectedAtIndex:(int)indexPath.row];
        }
    }

    [_theTableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 1) {
        if ([[TaskController sharedController]numberOfTasks] > 0) {
            return [[[TaskController sharedController]taskAtIndex:(int)indexPath.row]canSelect]?indexPath:nil;
        }
    }
    return indexPath;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Cancel";
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1 && indexPath.row < [[TaskController sharedController]numberOfTasks]) {
        return [[[TaskController sharedController]taskAtIndex:(int)indexPath.row]canStop];
    }
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [[TaskController sharedController]removeTaskAtIndex:(int)indexPath.row];
        [_theTableView beginUpdates];
        [_theTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        if ([[TaskController sharedController]numberOfTasks] == 0) {
            [_theTableView deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        [_theTableView endUpdates];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _theTableView.frame = self.bounds;
}

- (void)drawRect:(CGRect)rect {
    if (self.alpha == 1.0f) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSaveGState(context);
        
        CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
        CGContextFillRect(context, self.bounds);
        
        CGContextSetStrokeColorWithColor(context, [UIColor darkGrayColor].CGColor);
        CGContextSetLineWidth(context, 0.5);
        
        float width = (_viewToMove == nil)?150:self.bounds.size.width;
        
        CGContextMoveToPoint(context, width, self.bounds.size.height);
        CGContextAddLineToPoint(context, width, 0);
        
        CGContextStrokePath(context);
        
        CGContextRestoreGState(context);
    } else {
        [super drawRect:rect];
    }
}

- (void)dealloc {
    [self setViewToMove:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end

