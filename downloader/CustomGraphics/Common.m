//
//  Common.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 9/29/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import "Common.h"

CGRect rectFor1PxStroke(CGRect rect) {
    return CGRectMake(rect.origin.x + 0.5, rect.origin.y + 0.5, rect.size.width - 1, rect.size.height - 1);
}

void drawLinearGradient(CGContextRef context, CGRect rect, CGColorRef startColor, CGColorRef  endColor) {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat locations[] = { 0.0, 1.0 };
    
    NSArray *colors = [NSArray arrayWithObjects:(id)startColor, (id)endColor, nil];
    
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (CFArrayRef) colors, locations);
    
    CGPoint startPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
    CGPoint endPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
    
    CGContextSaveGState(context);
    CGContextAddRect(context, rect);
    CGContextClip(context);
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    CGContextRestoreGState(context);
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
}

void draw1PxStroke(CGContextRef context, CGPoint startPoint, CGPoint endPoint, CGColorRef color) {
    
    CGContextSaveGState(context);
    CGContextSetLineCap(context, kCGLineCapSquare);
    CGContextSetStrokeColorWithColor(context, color);
    CGContextSetLineWidth(context, 1.0);
    CGContextMoveToPoint(context, startPoint.x + 0.5, startPoint.y + 0.5);
    CGContextAddLineToPoint(context, endPoint.x + 0.5, endPoint.y + 0.5);
    CGContextStrokePath(context);
    CGContextRestoreGState(context);        
}

void drawGlossAndGradient(CGContextRef context, CGRect rect, CGColorRef startColor, CGColorRef endColor) {
    
    drawLinearGradient(context, rect, startColor, endColor);
    
    CGColorRef glossColor1 = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.35].CGColor;
    CGColorRef glossColor2 = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.1].CGColor;
    
    CGRect topHalf = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height/2);
    
    drawLinearGradient(context, topHalf, glossColor1, glossColor2);
    
}

CGMutablePathRef createArcPathFromBottomOfRect(CGRect rect, CGFloat arcHeight) {
    
    CGRect arcRect = CGRectMake(rect.origin.x, rect.origin.y+rect.size.height-arcHeight, rect.size.width, arcHeight);
    
    CGFloat arcRadius = (arcRect.size.height/2)+(pow(arcRect.size.width, 2)/(8*arcRect.size.height));
    CGPoint arcCenter = CGPointMake(arcRect.origin.x+arcRect.size.width/2, arcRect.origin.y+arcRadius);
    
    CGFloat angle = acos(arcRect.size.width/(2*arcRadius));
    CGFloat startAngle = radians(180)+angle;
    CGFloat endAngle = radians(360)-angle;
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddArc(path, nil, arcCenter.x, arcCenter.y, arcRadius, startAngle, endAngle, 0);
    CGPathAddLineToPoint(path, nil, CGRectGetMaxX(rect), CGRectGetMinY(rect));
    CGPathAddLineToPoint(path, nil, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGPathAddLineToPoint(path, nil, CGRectGetMinX(rect), CGRectGetMaxY(rect));
    return path;    
}

UIImage * getButtonImage(void) {
    CGFloat width = 11; // for saving as an image, use 22
    CGFloat height = 30; // for saving as an image, use 60
    
    UIGraphicsBeginImageContext(CGSizeMake(width, height));		
    CGContextRef context = UIGraphicsGetCurrentContext();		
    UIGraphicsPushContext(context);								

    CGColorRef lightColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0].CGColor;
    CGColorRef darkColor = [UIColor darkGrayColor].CGColor;
    
    CGRect _coloredBoxRect = CGRectMake(0, 0, width, height);
    
    // Draw gloss and gradient
    drawGlossAndGradient(context, _coloredBoxRect, lightColor, darkColor);  
    
    // Draw stroke
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextSetLineWidth(context, 1.5);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextStrokeRect(context, rectFor1PxStroke(_coloredBoxRect));
    
    // pop context 
    UIGraphicsPopContext();								
    
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    return outputImage;
}

UIImage * getButtonImagePressed(void) {
    CGFloat width = 11; // for saving as an image, use 22
    CGFloat height = 30; // for saving as an image, use 60
    
    UIGraphicsBeginImageContext(CGSizeMake(width, height));		
    CGContextRef context = UIGraphicsGetCurrentContext();		
    UIGraphicsPushContext(context);								

    CGColorRef lightColor = [UIColor colorWithRed:105.0f/255.0f green:179.0f/255.0f blue:216.0f/255.0f alpha:1.0].CGColor;
    CGColorRef darkColor = [UIColor colorWithRed:21.0/255.0 green:92.0/255.0 blue:136.0/255.0 alpha:1.0].CGColor; 
    
    CGRect _coloredBoxRect = CGRectMake(0, 0, width, height);
    
    // Draw gloss and gradient
    drawGlossAndGradient(context, _coloredBoxRect, lightColor, darkColor);  
    
    // Draw stroke
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextSetLineWidth(context, 1.5);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextStrokeRect(context, rectFor1PxStroke(_coloredBoxRect));
    
    
    // pop context 
    UIGraphicsPopContext();								
    
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    return outputImage;
}


UIImage * getUIButtonImageNonPressed(CGFloat height) {
    CGFloat width = 11; // for saving as an image, use 22

    UIGraphicsBeginImageContext(CGSizeMake(width, height));		
    CGContextRef context = UIGraphicsGetCurrentContext();		
    UIGraphicsPushContext(context);								
    
    CGColorRef lightColor = [UIColor colorWithRed:105.0f/255.0f green:179.0f/255.0f blue:216.0f/255.0f alpha:1.0].CGColor;
    CGColorRef darkColor = [UIColor colorWithRed:21.0/255.0 green:92.0/255.0 blue:136.0/255.0 alpha:1.0].CGColor;
    CGColorRef shadowColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.5].CGColor;   
    
    CGRect _coloredBoxRect = CGRectMake(0, 0, width, height);
    
    // Draw shadow
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context, CGSizeMake(0, 0), 1.0, shadowColor);
    CGContextSetFillColorWithColor(context, lightColor);
    CGContextFillRect(context, _coloredBoxRect);
    CGContextRestoreGState(context);
    
    // Draw gloss and gradient
    drawGlossAndGradient(context, _coloredBoxRect, lightColor, darkColor);  
    
    // Draw stroke
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextSetLineWidth(context, 1.5);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextStrokeRect(context, rectFor1PxStroke(_coloredBoxRect));
    
    // pop context 
    UIGraphicsPopContext();								
    
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    return outputImage;
}

UIImage * getUIButtonImagePressed(CGFloat height) {
    CGFloat width = 11; // for saving as an image, use 22
    
    UIGraphicsBeginImageContext(CGSizeMake(width, height));		
    CGContextRef context = UIGraphicsGetCurrentContext();		
    UIGraphicsPushContext(context);								

    CGColorRef lightColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0].CGColor;
    CGColorRef darkColor = [UIColor darkGrayColor].CGColor;
    CGColorRef shadowColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.5].CGColor;   
    
    CGRect _coloredBoxRect = CGRectMake(0, 0, width, height);
    
    // Draw shadow
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context, CGSizeMake(0, 0), 1.0, shadowColor);
    CGContextSetFillColorWithColor(context, lightColor);
    CGContextFillRect(context, _coloredBoxRect);
    CGContextRestoreGState(context);
    
    // Draw gloss and gradient
    drawGlossAndGradient(context, _coloredBoxRect, lightColor, darkColor);  
    
    // Draw stroke
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextSetLineWidth(context, 1.5);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextStrokeRect(context, rectFor1PxStroke(_coloredBoxRect));
    
    // pop context 
    UIGraphicsPopContext();								
    
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    return outputImage;
}

UIImage * getCheckmarkImage(void) {
    UIGraphicsBeginImageContext(CGSizeMake(60, 60));
    CGContextRef context = UIGraphicsGetCurrentContext();		
    UIGraphicsPushContext(context);
    
    float multConstant = 2;
    
    CGPoint one = CGPointMake(24*multConstant, 4.5*multConstant);
    CGPoint two = CGPointMake(28*multConstant, 8*multConstant);
    CGPoint three = CGPointMake(10*multConstant, 24*multConstant);
    CGPoint four = CGPointMake(1.5*multConstant, 16.5*multConstant);
    CGPoint five = CGPointMake(5*multConstant, 13*multConstant);
    CGPoint six = CGPointMake(10*multConstant, 17*multConstant);
    CGPoint seven = CGPointMake(24*multConstant, 4.5*multConstant);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, nil, one.x, one.y);
    CGPathAddLineToPoint(path, nil, one.x, one.y);
    CGPathAddLineToPoint(path, nil, two.x, two.y);
    CGPathAddLineToPoint(path, nil, three.x, three.y);
    CGPathAddLineToPoint(path, nil, four.x, four.y);
    CGPathAddLineToPoint(path, nil, five.x, five.y);
    CGPathAddLineToPoint(path, nil, six.x, six.y);
    CGPathAddLineToPoint(path, nil, seven.x, seven.y);
    
    CGContextSaveGState(context);
    
    CGContextAddPath(context, path);
    CGContextClip(context);
    drawLinearGradient(context, CGContextGetClipBoundingBox(context), [UIColor colorWithWhite:0.7 alpha:1.0].CGColor, [UIColor whiteColor].CGColor);
    
    CGPathRelease(path);
    
    CGContextRestoreGState(context);
    
    UIGraphicsPopContext();								
    
    UIImage *outputImage = [UIImage imageWithCGImage:UIGraphicsGetImageFromCurrentImageContext().CGImage scale:2.0 orientation:UIImageOrientationUp];
    
    UIGraphicsEndImageContext();
    return outputImage;
}

UIImage * getNavBarImage(void) {
    
    UIGraphicsBeginImageContext(CGSizeMake(22, 88));		
    CGContextRef context = UIGraphicsGetCurrentContext();		
    UIGraphicsPushContext(context);

    CGColorRef shadowColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.5].CGColor;
    
    CGRect _coloredBoxRect = CGRectMake(0, 0, 22, 88);
    
    // Draw shadow
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context, CGSizeMake(0, 2), 3.0, shadowColor);
    CGContextSetFillColorWithColor(context, LIGHT_BLUE);
    CGContextFillRect(context, _coloredBoxRect);
    CGContextRestoreGState(context);
    
    // Draw gloss and gradient
    drawGlossAndGradient(context, _coloredBoxRect, LIGHT_BLUE, DARK_BLUE);
    
    // Draw stroke
    CGContextSetStrokeColorWithColor(context, DARK_BLUE);
    CGContextSetLineWidth(context, 1.0);    
    CGContextStrokeRect(context, rectFor1PxStroke(_coloredBoxRect));
    
    UIGraphicsPopContext();								
    
    UIImage *outputImage = [UIImage imageWithCGImage:UIGraphicsGetImageFromCurrentImageContext().CGImage scale:2.0 orientation:UIImageOrientationUp];
    
    UIGraphicsEndImageContext();
    return outputImage;
}

UIColor * UIColorFromRGB(float red, float green, float blue) {
    return [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
}

@implementation UIImage (resizing_additions)

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();    
    UIGraphicsEndImageContext();
    return newImage;
}

+ (UIImage *)imageWithImage:(UIImage *)image strechedToSize:(CGSize)size {
    UIGraphicsBeginImageContext(size);		
    CGContextRef context = UIGraphicsGetCurrentContext();		
    UIGraphicsPushContext(context);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIGraphicsPopContext();
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return outputImage;
}

@end



