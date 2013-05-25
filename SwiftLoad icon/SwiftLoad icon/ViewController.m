//
//  ViewController.m
//  SwiftLoad icon
//
//  Created by Nate Symer on 5/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>
#import "Common.h"
#import "UIImage+Additions.h"

@implementation ViewController

@synthesize imageView;

- (CGRect)getBoundsForString:(NSString *)string {
    int charCount = [string length];
    CGGlyph glyphs[charCount];
    CGRect rects[charCount];
    
   // CGFontRef theCTFont = CGFontCreateWithFontName((CFStringRef)[UIFont systemFontOfSize:30].fontName);
    UIFont *font = [UIFont systemFontOfSize:400];
    
    CTFontRef theCTFont = CTFontCreateWithName((CFStringRef)font.fontName, font.pointSize, NULL);
    
    CTFontGetGlyphsForCharacters(theCTFont, (const unichar*)[string cStringUsingEncoding:NSUnicodeStringEncoding], glyphs, charCount);
    CTFontGetBoundingRectsForGlyphs(theCTFont, kCTFontDefaultOrientation, glyphs, rects, charCount);
    
    int totalwidth = 0, maxheight = 0;
    for (int i=0; i < charCount; i++)
    {
        totalwidth += rects[i].size.width;
        maxheight = maxheight < rects[i].size.height ? rects[i].size.height : maxheight;
    }
    
    return CGRectMake(0, 0, totalwidth, maxheight);
}

- (UIImage *)getIconImage {
    CGRect pseudoBounds = CGRectMake(0, 0, 512, 512);

    UIGraphicsBeginImageContext(CGSizeMake(512, 512));		
    CGContextRef context = UIGraphicsGetCurrentContext();		
    UIGraphicsPushContext(context);	
    
    //
    // Draw Background
    //
    CGContextSaveGState(context);
    CGColorRef redColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0].CGColor;  // 0.55
    CGColorRef asdfColor = [UIColor colorWithRed:0.55 green:0.55 blue:0.55 alpha:1.0].CGColor;    // 0.6
    
    CGContextSetFillColorWithColor(context, redColor);
    CGContextFillRect(context, pseudoBounds);
    
    CGContextRestoreGState(context);
    
    CGContextSaveGState(context); //Save Context State Before Clipping "hatchPath"
    
    CGFloat spacer = 120.0f;
    int rows = (pseudoBounds.size.width + pseudoBounds.size.height/spacer);
    CGFloat padding = 0.0f;
    CGMutablePathRef hatchPath = CGPathCreateMutable();
    for(int i =  1; i<=rows; i++) {
        CGPathMoveToPoint(hatchPath, NULL, spacer * i, padding);
        CGPathAddLineToPoint(hatchPath, NULL, padding, spacer * i);
    }
    CGContextAddPath(context, hatchPath);
    CGPathRelease(hatchPath);
    CGContextSetLineWidth(context, 40.0f);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetStrokeColorWithColor(context, asdfColor);
    CGContextDrawPath(context, kCGPathStroke);
    CGContextRestoreGState(context); //Restore Last Context State Before Clipping "hatchPath"

    
    //
    // Draw S
    //
    
    CGContextSaveGState(context);
    
    char* text = "S";
    CGContextSelectFont(context, "Helvetica-Bold", 500, kCGEncodingMacRoman); // 400 is centered
    CGAffineTransform xform = CGAffineTransformMake(1.0,  0.0, 0.0, -1.0, 0.0,  0.0);
    CGContextSetTextMatrix(context, xform);
    
    float y = (pseudoBounds.size.height/2)+170; // 128 for 400
    float x = (pseudoBounds.size.width/2)-160; // 128 for 400
    
    float shadowConstant = 6;
    
    // draw text with top shadow
    CGContextSetTextDrawingMode(context, kCGTextFill);
    CGContextSetShadowWithColor(context, CGSizeMake(0, -shadowConstant), 8, [UIColor blackColor].CGColor);
    CGContextShowTextAtPoint(context, x, y, text, strlen(text));
    
    // draw text with bottom shadow
    CGContextSetShadowWithColor(context, CGSizeMake(0, shadowConstant), 8, [UIColor blackColor].CGColor);
    CGContextShowTextAtPoint(context, x, y, text, strlen(text));
    
    // draw text with left shadow
    CGContextSetShadowWithColor(context, CGSizeMake(-shadowConstant, 0), 8, [UIColor blackColor].CGColor);
    CGContextShowTextAtPoint(context, x, y, text, strlen(text));  
    
    // draw text with right shadow
    CGContextSetShadowWithColor(context, CGSizeMake(shadowConstant, 0), 8, [UIColor blackColor].CGColor);
    CGContextShowTextAtPoint(context, x, y, text, strlen(text));  
    
    // clip to letter
    CGContextSetTextDrawingMode(context, kCGTextClip);
    CGContextShowTextAtPoint(context, x, y, text, strlen(text)); 
    
    drawLinearGradient(context, pseudoBounds, LIGHT_BLUE, DARK_BLUE_TWO);
    
    CGContextRestoreGState(context);
    UIGraphicsPopContext();								
    
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    return outputImage;

}

- (UIImage *)getSplashImage {
   // iPad retina 2048 × 1536
    
    CGRect pseudoBounds = CGRectMake(0, 0, 1536, 2028);
    
    UIGraphicsBeginImageContext(CGSizeMake(1536, 2048));		
    CGContextRef context = UIGraphicsGetCurrentContext();		
    UIGraphicsPushContext(context);	

    
    CGContextSaveGState(context);
    CGColorRef redColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0].CGColor;  // 0.55
    CGColorRef asdfColor = [UIColor colorWithRed:0.55 green:0.55 blue:0.55 alpha:1.0].CGColor;    // 0.6
    
    CGContextSetFillColorWithColor(context, redColor);
    CGContextFillRect(context, pseudoBounds);
    
    CGContextRestoreGState(context);
    
    CGContextSaveGState(context); //Save Context State Before Clipping "hatchPath"
    
    CGFloat spacer = 120.0f;
    int rows = (pseudoBounds.size.width + pseudoBounds.size.height/spacer);
    CGFloat padding = 0.0f;
    CGMutablePathRef hatchPath = CGPathCreateMutable();
    for(int i = 1; i<rows; i++) {
        CGPathMoveToPoint(hatchPath, NULL, spacer * i, padding);
        CGPathAddLineToPoint(hatchPath, NULL, padding, spacer * i);
    }
    CGContextAddPath(context, hatchPath);
    CGPathRelease(hatchPath);
    CGContextSetLineWidth(context, 40.0f);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetStrokeColorWithColor(context, asdfColor);
    CGContextDrawPath(context, kCGPathStroke);
    CGContextRestoreGState(context); //Restore Last Context State Before Clipping "hatchPath" 
    
    UIGraphicsPopContext();								
    
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    return outputImage;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIImage *image = [self getIconImage];
    [imageView setImage:image];
    
    UIImage *iPadRetina = [image scaleToSize:CGSizeMake(144, 144)];
    UIImage *iPad = [image scaleToSize:CGSizeMake(72, 72)];
    UIImage *iPhoneRetina = [image scaleToSize:CGSizeMake(114, 114)];
    UIImage *iPhone = [image scaleToSize:CGSizeMake(57, 57)];
    
    [UIImagePNGRepresentation(image) writeToFile:@"/Users/wiedmersymer/Desktop/SwiftloadIconry/iTunesArtwork.png" atomically:YES];
    [UIImagePNGRepresentation(iPadRetina) writeToFile:@"/Users/wiedmersymer/Desktop/SwiftloadIconry/icon~iPad@2x.png" atomically:YES];
    [UIImagePNGRepresentation(iPad) writeToFile:@"/Users/wiedmersymer/Desktop/SwiftloadIconry/icon~iPad.png" atomically:YES];
    [UIImagePNGRepresentation(iPhoneRetina) writeToFile:@"/Users/wiedmersymer/Desktop/SwiftloadIconry/icon@2x.png" atomically:YES];
    [UIImagePNGRepresentation(iPhone) writeToFile:@"/Users/wiedmersymer/Desktop/SwiftloadIconry/icon.png" atomically:YES];
    
    UIImage *iPadRetinaS = [self getSplashImage];
    UIImage *iPadS = [iPadRetinaS scaleToSize:CGSizeMake(768, 1004)];
    UIImage *iPhoneRetinaS = [iPadRetinaS scaleToSize:CGSizeMake(640, 960)];
    UIImage *iPhoneS = [iPadRetinaS scaleToSize:CGSizeMake(320, 460)];
    
    [UIImagePNGRepresentation(iPadRetinaS) writeToFile:@"/Users/wiedmersymer/Desktop/SwiftloadIconry/Default~iPad@2x.png" atomically:YES];
    [UIImagePNGRepresentation(iPadS) writeToFile:@"/Users/wiedmersymer/Desktop/SwiftloadIconry/Default~iPad.png" atomically:YES];
    [UIImagePNGRepresentation(iPhoneRetinaS) writeToFile:@"/Users/wiedmersymer/Desktop/SwiftloadIconry/Default@2x.png" atomically:YES];
    [UIImagePNGRepresentation(iPhoneS) writeToFile:@"/Users/wiedmersymer/Desktop/SwiftloadIconry/Default.png" atomically:YES];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)dealloc {
    [imageView release];
    [super dealloc];
}

@end
