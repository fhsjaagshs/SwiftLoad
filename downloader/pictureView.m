//
//  pictureView.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 10/27/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import "pictureView.h"

@implementation pictureView

- (void)loadView {
    [super loadView];
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    
    self.navBar = [[ShadowedNavBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)];
    self.navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:[[kAppDelegate openFile]lastPathComponent]];
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showActionSheet:)];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    [self.navBar pushNavigationItem:topItem animated:YES];
    [self.view addSubview:self.navBar];
    [self.view bringSubviewToFront:self.navBar];
    
    self.toolBar = [[ShadowedToolbar alloc]initWithFrame:CGRectMake(0, screenBounds.size.height-44, screenBounds.size.width, 44)];
    self.toolBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    
    UIBarButtonItem *space = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    self.nextImg = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"ArrowRight"] style:UIBarButtonItemStylePlain target:self action:@selector(nextImage)];
    [self.nextImg setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    self.prevImg = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"ArrowLeft"] style:UIBarButtonItemStylePlain target:self action:@selector(previousImage)];
    [self.prevImg setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    
    self.toolBar.items = [NSArray arrayWithObjects:space, self.prevImg, space, self.nextImg, space, nil];
    [self.view addSubview:self.toolBar];
    [self.view bringSubviewToFront:self.toolBar];
    
    self.zoomingImageView = [[ZoomingImageView alloc]initWithFrame:CGRectMake(0, 44, screenBounds.size.width, screenBounds.size.height-88)];
    self.zoomingImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.view addSubview:self.zoomingImageView];
    [self.view bringSubviewToFront:self.zoomingImageView];
    
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication]statusBarOrientation])) {
            [self.toolBar setHidden:YES];
            [self.navBar setHidden:YES];
            [[UIApplication sharedApplication]setStatusBarHidden:YES];
            self.view.frame = [[UIScreen mainScreen]bounds];
            self.zoomingImageView.frame = self.view.frame;
        }
    }
    
    UITapGestureRecognizer *tt = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(imageViewWasDoubleTapped:)];
    [tt setNumberOfTapsRequired:2];
    [tt setNumberOfTouchesRequired:1];
    [tt setDelegate:self];
    [self.zoomingImageView addGestureRecognizer:tt];
    
    NSString *currentDir = [kAppDelegate managerCurrentDir];
    NSArray *filesOfDir = [[[NSFileManager defaultManager]contentsOfDirectoryAtPath:currentDir error:nil]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSMutableArray *imageFiles = [[NSMutableArray alloc]init];
    
    for (NSString *object in filesOfDir) {
        NSString *newObject = [currentDir stringByAppendingPathComponent:object];
        if ([MIMEUtils isImageFile:newObject]) {
            [imageFiles addObject:newObject];
        }
    }
    
    int numberInArray = [imageFiles indexOfObject:[kAppDelegate openFile]];
    
    if (imageFiles.count == 1) {
        [self.nextImg setEnabled:NO];
        [self.prevImg setEnabled:NO];
    }
    
    if (numberInArray == 0) {
        [self.prevImg setEnabled:NO];
    }
    
    if (numberInArray == imageFiles.count-1) {
        [self.nextImg setEnabled:NO];
    }
    
    [[NSUserDefaults standardUserDefaults]setInteger:numberInArray forKey:@"imageNumber"];
    
    [imageFiles removeAllObjects];

    [self.zoomingImageView loadImage:[UIImage imageWithContentsOfFile:[kAppDelegate openFile]]];
}

- (void)addToTheRoll {
    
    [kAppDelegate showHUDWithTitle:@"Working..."];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {

            NSString *file = [kAppDelegate openFile];
            UIImage *image = [[UIImage alloc]initWithContentsOfFile:file];
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
            
            [NSThread sleepForTimeInterval:0.5f];

            dispatch_sync(dispatch_get_main_queue(), ^{
                @autoreleasepool {

                    NSString *fileName = [file lastPathComponent];
                    
                    if (fileName.length > 14) {
                        fileName = [[fileName substringToIndex:11]stringByAppendingString:@"..."];
                    }
                    
              //  UIImageView *checkmark = [[UIImageView alloc]initWithImage:getCheckmarkImage()];
                    
                    [kAppDelegate hideHUD];
                    
                    [kAppDelegate showHUDWithTitle:@"Imported"];
                    [kAppDelegate setSecondaryTitleOfVisibleHUD:fileName];
                    [kAppDelegate setVisibleHudMode:MBProgressHUDModeCustomView];
              //  [kAppDelegate setVisibleHudCustomView:checkmark];
                    [kAppDelegate hideVisibleHudAfterDelay:1.0f];
               // [checkmark release];
                }
            });
        
        }
    });
}

- (void)close {
    [self dismissModalViewControllerAnimated:YES];
    [[UIApplication sharedApplication]setStatusBarHidden:NO];
    self.view.frame = [[UIScreen mainScreen]applicationFrame];
    [kAppDelegate setOpenFile:nil];
}

// Action in reverse is Noitca
- (void)showActionSheet:(id)sender {
    
    if (self.popupQuery && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.popupQuery dismissWithClickedButtonIndex:self.popupQuery.cancelButtonIndex animated:YES];
        self.popupQuery = nil;
        return;
    }
    
    NSString *file = [kAppDelegate openFile];
    NSString *fileName = [file lastPathComponent];

    self.popupQuery = [[UIActionSheet alloc]initWithTitle:[NSString stringWithFormat:@"What would you like to do with %@?",fileName] completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
        
        if (buttonIndex == 0) {
            [kAppDelegate printFile:file fromView:self.view];
        } else if (buttonIndex == 1) {
            [kAppDelegate sendFileInEmail:file fromViewController:self];
        } else if (buttonIndex == 2) {
            BluetoothTask *task = [BluetoothTask taskWithFile:[kAppDelegate openFile]];
            [[TaskController sharedController]addTask:task];
        } else if (buttonIndex == 3) {
            [kAppDelegate uploadLocalFile:[kAppDelegate openFile] fromViewController:self];
        } else if (buttonIndex == 4) {
            if ([MIMEUtils isImageFile:file]) {
                [self addToTheRoll];
            } else {
                NSString *message = [[NSString alloc]initWithFormat:@"Swift was unable to add \"%@\" to the camera roll.",fileName];
                [TransparentAlert showAlertWithTitle:@"Import Failure" andMessage:message];
            }
        }
    } cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Print", @"Email File", @"Send Via Bluetooth", @"Upload to Dropbox", @"Add to Photo Library", nil];
    
    self.popupQuery.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.popupQuery showFromBarButtonItem:(UIBarButtonItem *)sender animated:YES];
    } else {
        [self.popupQuery showInView:self.view];
    }
}

- (void)nextImage {
    [self.prevImg setEnabled:YES];
    
    int oldImageNumber = [[NSUserDefaults standardUserDefaults]integerForKey:@"imageNumber"];

    NSString *currentDir = [kAppDelegate managerCurrentDir];
    NSArray *filesOfDir = [[[NSFileManager defaultManager]contentsOfDirectoryAtPath:currentDir error:nil]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSMutableArray *imageFiles = [[NSMutableArray alloc]init];
    
    for (NSString *object in filesOfDir) {
        NSString *newObject = [currentDir stringByAppendingPathComponent:object];
        if ([MIMEUtils isImageFile:newObject]) {
            [imageFiles addObject:newObject];
        }
    }

    int newImageNumber = oldImageNumber+1;
    NSString *newImagePath = [imageFiles objectAtIndex:newImageNumber];
    
    int lastImage = [imageFiles indexOfObject:[imageFiles lastObject]];
    
    [imageFiles removeAllObjects];
    
    if (lastImage == newImageNumber) {
        [self.nextImg setEnabled:NO];
    }
    
  //  self.zoomingImageView.zoomScale = self.zoomingImageView.minimumZoomScale;
    [self.zoomingImageView loadImage:[UIImage imageWithContentsOfFile:newImagePath]];

    [kAppDelegate setOpenFile:newImagePath];
    [[NSUserDefaults standardUserDefaults]setInteger:newImageNumber forKey:@"imageNumber"];
    self.navBar.topItem.title = [newImagePath lastPathComponent];
}

- (void)previousImage {
    [self.nextImg setEnabled:YES];
    
    int oldImageNumber = [[NSUserDefaults standardUserDefaults]integerForKey:@"imageNumber"];

    NSString *currentDir = [kAppDelegate managerCurrentDir];
    NSArray *filesOfDir = [[[NSFileManager defaultManager]contentsOfDirectoryAtPath:currentDir error:nil]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSMutableArray *imageFiles = [[NSMutableArray alloc]init];
    
    for (NSString *object in filesOfDir) {
        NSString *newObject = [currentDir stringByAppendingPathComponent:object];
        if ([MIMEUtils isImageFile:newObject]) {
            [imageFiles addObject:newObject];
        }
    }
    
    int newImageNumber = oldImageNumber-1;
    NSString *newImagePath = [imageFiles objectAtIndex:newImageNumber];
    
    [imageFiles removeAllObjects];
    
    if (newImageNumber == 0) {
        [self.prevImg setEnabled:NO];
    }
    
   // self.zoomingImageView.zoomScale = self.zoomingImageView.minimumZoomScale;
    [self.zoomingImageView loadImage:[UIImage imageWithContentsOfFile:newImagePath]];

    [kAppDelegate setOpenFile:newImagePath];
    [[NSUserDefaults standardUserDefaults]setInteger:newImageNumber forKey:@"imageNumber"];
    self.navBar.topItem.title = [newImagePath lastPathComponent];
}

- (void)imageViewWasDoubleTapped:(UIGestureRecognizer *)rec {
    if (self.zoomingImageView.zoomScale > 1) {
        [self.zoomingImageView zoomOut];
    } else {
        [self.zoomingImageView zoomToPoint:[rec locationInView:self.view] withScale:self.zoomingImageView.maximumZoomScale animated:YES];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    // To Portrait
    if (UIInterfaceOrientationIsLandscape(fromInterfaceOrientation)) {
        [self.toolBar setHidden:NO];
        [self.navBar setHidden:NO];
        [[UIApplication sharedApplication]setStatusBarHidden:NO];
        self.view.frame = [[UIScreen mainScreen]applicationFrame];
        self.zoomingImageView.frame = CGRectMake(0, 44, self.view.bounds.size.width, self.view.bounds.size.height-88);
    }
    [self.zoomingImageView resetAfterRotate];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    // To Landscape
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        [self.toolBar setHidden:YES];
        [self.navBar setHidden:YES];
        [[UIApplication sharedApplication]setStatusBarHidden:YES];
        self.view.frame = [[UIScreen mainScreen]bounds];
        self.zoomingImageView.frame = self.view.frame;
    }
    [self.zoomingImageView resetAfterRotate];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

@end