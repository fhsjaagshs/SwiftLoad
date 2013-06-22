//
//  BlurryController.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 6/21/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "BlurryController.h"
//#import "GPUImage.h"

@implementation BlurryController

// GPUImage
- (void)blur {
    GPUImageFastBlurFilter *blurFilter = [[[GPUImageFastBlurFilter alloc]init]autorelease];
    blurFilter.blurSize = 1.0;
    
    UIGraphicsBeginImageContext(self.bounds.size);
    [[[[UIApplication sharedApplication]delegate]window].layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    UIImage *result = [blurFilter imageByFilteringImage:image];
    UIImageView *view = [[[UIImageView alloc]initWithFrame:self.bounds]autorelease];
    view.backgroundColor = [UIColor clearColor];
    view.image = result;
    [self addSubview:view];
}

// CoreImage
- (void)doBlur {
    UIGraphicsBeginImageContext(self.bounds.size);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //Blur the UIImage
    CIImage *imageToBlur = [CIImage imageWithCGImage:viewImage.CGImage];
    CIFilter *gaussianBlurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [gaussianBlurFilter setValue:imageToBlur forKey:@"inputImage"];
    [gaussianBlurFilter setValue:[NSNumber numberWithFloat:10] forKey:@"inputRadius"]; //change number to increase/decrease blur
    CIImage *resultImage = [gaussianBlurFilter valueForKey:@"outputImage"];
    
    //create UIImage from filtered image
    UIImage *blurrredImage = [[UIImage alloc] initWithCIImage:resultImage];
    
    //Place the UIImage in a UIImageView
    UIImageView *newView = [[UIImageView alloc] initWithFrame:self.bounds];
    newView.image = blurrredImage;
    
    //insert blur UIImageView below transparent view inside the blur image container
    [self insertSubview:newView belowSubview:nil];
}

- (void)show {
    [[[[UIApplication sharedApplication]delegate]window]addSubview:self];
    [[[[UIApplication sharedApplication]delegate]window]bringSubviewToFront:self];
    [self blur];
}

- (void)didRotate:(NSNotification *)notification {
    //[self doBlur];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(didRotate:) name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    return self;
}

+ (BlurryController *)blurryControllerWithFrame:(CGRect)frame {
    return [[[[self class]alloc]initWithFrame:frame]autorelease];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [super dealloc];
}

@end
