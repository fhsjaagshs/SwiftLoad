//
//  Common.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 9/29/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

#define LIGHT_BLUE [UIColor colorWithRed:105.0f/255.0f green:179.0f/255.0f blue:216.0f/255.0f alpha:1.0].CGColor
#define DARK_BLUE [UIColor colorWithRed:21.0/255.0 green:92.0/255.0 blue:136.0/255.0 alpha:1.0].CGColor
#define LIGHT_GRAY [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0].CGColor
#define DARK_GRAY [UIColor darkGrayColor].CGColor
#define SHADOW_COLOR [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.5].CGColor

#define LIGHT_PURPLE [UIColor colorWithRed:147.0/255.0 green:105.0/255.0 blue:216.0/255.0 alpha:1.0].CGColor
#define DARK_PURPLE [UIColor colorWithRed:72.0/255.0 green:22.0/255.0 blue:137.0/255.0 alpha:1.0].CGColor


void drawLinearGradient(CGContextRef context, CGRect rect, CGColorRef startColor, CGColorRef  endColor);
CGRect rectFor1PxStroke(CGRect rect);
void draw1PxStroke(CGContextRef context, CGPoint startPoint, CGPoint endPoint, CGColorRef color);
void drawGlossAndGradient(CGContextRef context, CGRect rect, CGColorRef startColor, CGColorRef endColor);
static inline double radians (double degrees) { return degrees * M_PI/180; }
CGMutablePathRef createArcPathFromBottomOfRect(CGRect rect, CGFloat arcHeight);
UIImage * getButtonImage(void);
UIImage * getUIButtonImageNonPressed(CGFloat height);
UIImage * getUIButtonImagePressed(CGFloat height);
UIImage * getButtonImagePressed(void);
UIImage * getCheckmarkImage(void);
UIImage * getNavBarImage(void);
//UIImage * getInnerShadowImage(void);
UIColor * UIColorFromRGB(float red, float green, float blue);
//CGPathRef newPathForRoundedRect(CGRect rect, CGFloat radius);




// A good blue color: 100 200 100

@interface UIImage (resizing_additions)

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;

+ (UIImage *)imageWithImage:(UIImage *)image strechedToSize:(CGSize)size;

@end

