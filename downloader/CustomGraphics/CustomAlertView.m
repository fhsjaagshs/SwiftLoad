//
//  CustomAlertView.m
//  CustomAlert
//
//  Created by Nathaniel Symer on 10/14/11.
//  Copyright (c) 2011 Nathaniel Symer. All rights reserved.
//

#import "CustomAlertView.h"
#import "Common.h"

@implementation CustomAlertView

- (void)layoutSubviews {
    
	for (UIView *subview in self.subviews) {
		
		if ([subview isMemberOfClass:[UIImageView class]]) {
			[subview removeFromSuperview];
		}
        
        if ([subview isKindOfClass:[UIControl class]] && ![subview isKindOfClass:[UITextField class]]) {
            subview.frame = CGRectMake(subview.frame.origin.x+2.5, subview.frame.origin.y, subview.frame.size.width-5, 37);
            UIImage *buttonImage = [getUIButtonImageNonPressed(subview.frame.size.height) resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)];
            [(UIButton *)subview setBackgroundImage:buttonImage forState:UIControlStateNormal];
            
            UIImage *buttonImagePressed = [getUIButtonImagePressed(subview.frame.size.height) resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)];
            [(UIButton *)subview setBackgroundImage:buttonImagePressed forState:UIControlStateHighlighted];
        }
        
		if ([subview isMemberOfClass:[UILabel class]]) { //Point to UILabels To Change Text
			UILabel *label = (UILabel*)subview;	//Cast From UIView to UILabel
			label.textColor = [UIColor colorWithRed:210.0f/255.0f green:210.0f/255.0f blue:210.0f/255.0f alpha:1.0f];
			label.shadowColor = [UIColor blackColor];
			label.shadowOffset = CGSizeMake(0.0f, 1.0f);
		}
	}
}

- (void)drawRect:(CGRect)rect  {
    
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	CGRect activeBounds = self.bounds;
	CGFloat inset = 6.5f;	
	CGFloat originX = activeBounds.origin.x+inset;
	CGFloat originY = activeBounds.origin.y+inset;
	CGFloat width = activeBounds.size.width-(inset*2.0f);
	CGFloat height = activeBounds.size.height-(inset*2.0f);
    
    CGPathRef path = [UIBezierPath bezierPathWithRect:CGRectMake(originX, originY, width, height)].CGPath;
	
	CGContextAddPath(context, path);
	CGContextSetFillColorWithColor(context, [UIColor colorWithRed:240.0f/255.0f green:240.0f/255.0f blue:240.0f/255.0f alpha:1.0f].CGColor);
	CGContextSetShadowWithColor(context, CGSizeMake(0.0f, 1.0f), 6.0f, [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:1.0f].CGColor);
    CGContextDrawPath(context, kCGPathFill);
	
	CGContextSaveGState(context);
	CGContextAddPath(context, path);
	CGContextClip(context);
	
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	size_t count = 3;
	CGFloat locations[3] = {0.0f, 0.57f, 1.0f}; 
	CGFloat components[12] = {70.0f/255.0f, 70.0f/225.0f, 70.0f/255.0f, 1.0f,     //1 - 70
                              70.0f/255.0f, 70.0f/255.0f, 70.0f/255.0f, 1.0f,     //2 - 55
                              70.0f/255.0f, 70.0f/255.0f, 70.0f/255.0f, 1.0f};	  //3 - 40
    
	CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, components, locations, count);
    
	CGPoint startPoint = CGPointMake(activeBounds.size.width*0.5f, 0.0f);
	CGPoint endPoint = CGPointMake(activeBounds.size.width*0.5f, activeBounds.size.height);
    
	CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
	CGColorSpaceRelease(colorSpace);
	CGGradientRelease(gradient);

	CGContextAddPath(context, path);
	CGContextSetLineWidth(context, 3.0f);
	CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:210.0f/255.0f green:210.0f/255.0f blue:210.0f/255.0f alpha:1.0f].CGColor);
	CGContextSetShadowWithColor(context, CGSizeMake(0.0f, 0.0f), 6.0f, [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:1.0f].CGColor);
	CGContextDrawPath(context, kCGPathStroke);

    CGContextRestoreGState(context); 
	CGContextAddPath(context, path);
	CGContextSetLineWidth(context, 3.0f);
	CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:210.0f/255.0f green:210.0f/255.0f blue:210.0f/255.0f alpha:1.0f].CGColor);
	CGContextSetShadowWithColor(context, CGSizeMake(0.0f, 0.0f), 0.0f, [UIColor colorWithRed:0.0f green:0.0f blue:0.0f/255.0f alpha:0.1f].CGColor);
	CGContextDrawPath(context, kCGPathStroke);
}

@end

