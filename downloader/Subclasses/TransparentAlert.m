//
//  TransparentAlert.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/21/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "TransparentAlert.h"

@implementation TransparentAlert

+ (void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message {
    [[[TransparentAlert alloc]initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
}

- (id)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0.6 alpha:0.9];
        self.layer.cornerRadius = 5;
        self.layer.borderColor = [UIColor colorWithWhite:0.2 alpha:0.9].CGColor;
        self.layer.borderWidth = 2.5;
        self.opaque = NO;
    }
    return self;
}

- (UIImage *)drawButtonImage {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(5, 37), YES, [[UIScreen mainScreen]scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(context);
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 5, 37) cornerRadius:0];
    [[UIColor blackColor]setFill]; // alpha was 0.8f
    
    CGContextAddPath(context, path.CGPath);
    CGContextFillPath(context);
    
    UIGraphicsPopContext();
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)drawButtonImagePressed {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(5, 37), YES, [[UIScreen mainScreen]scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(context);

    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 5, 37) cornerRadius:0];
    [[UIColor colorWithWhite:1.0 alpha:0.8]setFill];
    
    CGContextAddPath(context, path.CGPath);
    CGContextFillPath(context);
    
    UIGraphicsPopContext();
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)layoutSubviews {
    
    [super layoutSubviews];
    
    UIImage *buttonImage = [[self drawButtonImage]resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)];
    UIImage *buttonImagePressed = [[self drawButtonImagePressed]resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)];
    
    Class UIAlertTextView = NSClassFromString(@"UIAlertTextView");
    Class UIButtonLabel = NSClassFromString(@"UIButtonLabel");
    
    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:[UIImageView class]]) {
            [subview removeFromSuperview];
		} else if ([subview isKindOfClass:[UILabel class]]) {
			UILabel *label = (UILabel *)subview;
            label.textColor = [UIColor blackColor];
            label.shadowOffset = CGSizeZero;
		} else if ([subview isKindOfClass:[UIControl class]] && ![subview isKindOfClass:[UITextField class]]) {
            
            if (self.numberOfButtons <= 2) {
                
                CGRect frame = subview.frame;
                
                frame.size.height = 37;
                frame.size.width = ((self.bounds.size.width-22-(22*(subview.tag-1)))/self.numberOfButtons);
                frame.origin.x = 11+((22+frame.size.width)*(subview.tag-1));
                frame.origin.y = self.bounds.size.height-47.5;
                
                subview.frame = frame;
            }

            for (UIView *subsubview in subview.subviews) {
                if ([subsubview isKindOfClass:UIButtonLabel]) {
                    UILabel *label = (UILabel *)subsubview;
                    label.shadowOffset = CGSizeZero;
                }
            }
            
            [(UIButton *)subview setBackgroundImage:buttonImage forState:UIControlStateNormal];
            [(UIButton *)subview setBackgroundImage:buttonImagePressed forState:UIControlStateHighlighted];
        } else if ([subview isKindOfClass:UIAlertTextView]) {
            [subview removeFromSuperview];
        }
	}
}

@end
