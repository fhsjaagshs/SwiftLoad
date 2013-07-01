#import "Common.h"

UIImage * getArrowImage() {
    CGFloat width = 56.4f;
    CGFloat height = 90.0f;
    CGFloat padding = 7.0f;
    
    UIGraphicsBeginImageContext(CGSizeMake(56.4f, 104.0f));
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(context);
    
    CGColorRef lightColor = LIGHT_BLUE;
    CGColorRef darkColor = DARK_BLUE;
    
    CGContextSaveGState(context);
    CGMutablePathRef overallPath = CGPathCreateMutable();
    
    CGPathMoveToPoint(overallPath, nil, width/2, padding);
    CGPathAddLineToPoint(overallPath, nil, width/2, padding);
    CGPathAddLineToPoint(overallPath, nil, width, (height/2)+padding);
    CGPathAddLineToPoint(overallPath, nil, (width/3)*2.2, (height/2)+padding);
    CGPathAddLineToPoint(overallPath, nil, (width/3)*2.2, height+padding);
    CGPathAddLineToPoint(overallPath, nil, (width/3)*0.8, height+padding);
    CGPathAddLineToPoint(overallPath, nil, (width/3)*0.8, (height/2)+padding);
    CGPathAddLineToPoint(overallPath, nil, 0, (height/2)+padding);
    CGPathAddLineToPoint(overallPath, nil, width/2, padding);
    
    CGContextAddPath(context, overallPath);
    CGContextClip(context);
    drawGlossAndGradient(context, CGRectMake(0, 0, 56.4f, 104.0f), lightColor, darkColor);
    
    CGContextRestoreGState(context);
    CGContextSaveGState(context);
    
    CGContextAddPath(context, overallPath);
    CGContextSetLineWidth(context, 2.0f);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextDrawPath(context, kCGPathStroke);
    
    CGContextRestoreGState(context);
    CGPathRelease(overallPath);
    
    UIGraphicsPopContext();
    
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    return outputImage;
}