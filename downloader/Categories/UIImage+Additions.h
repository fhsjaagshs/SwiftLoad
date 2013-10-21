//
//  UIImage+Additions.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 7/12/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

UIColor * RGBA(float red, float green, float blue, float alpha);
UIColor * RGB(float red, float green, float blue);

@interface UIImage (Additions)

- (UIImage *)imageFilledWith:(UIColor *)color;
//- (UIImage *)imageByRoundingCornersWithRadius:(float)radius;

@end

@interface UIColor (Additions)

- (UIImage *)imageWithSize:(CGSize)size;

@end