//
//  pictureView.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 10/27/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import "pictureView.h"

@implementation pictureView

@synthesize prevImg, nextImg, zoomingImageView, toolBar, popupQuery;

- (void)loadView {
    [super loadView];
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    
    self.view = [[[UIView alloc]initWithFrame:screenBounds]autorelease];
    self.view.backgroundColor = [UIColor clearColor];
    
    self.navBar = [[[CustomNavBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)]autorelease];
    self.navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[[UINavigationItem alloc]initWithTitle:[[kAppDelegate openFile]lastPathComponent]]autorelease];
    topItem.rightBarButtonItem = [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showNoitcaSheet:)]autorelease];
    topItem.leftBarButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)]autorelease];
    [self.navBar pushNavigationItem:topItem animated:YES];
    [self.view addSubview:self.navBar];
    [self.view bringSubviewToFront:self.navBar];
    
    self.toolBar = [[[CustomToolbar alloc]initWithFrame:CGRectMake(0, screenBounds.size.height-44, screenBounds.size.width, 44)]autorelease];
    self.toolBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    
    UIBarButtonItem *space = [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]autorelease];
    self.nextImg = [[[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"ArrowRight"] style:UIBarButtonItemStylePlain target:self action:@selector(nextImage)]autorelease];
    [self.nextImg setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    self.prevImg = [[[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"ArrowLeft"] style:UIBarButtonItemStylePlain target:self action:@selector(previousImage)]autorelease];
    [self.prevImg setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    
    self.toolBar.items = [NSArray arrayWithObjects:space, self.prevImg, space, self.nextImg, space, nil];
    [self.view addSubview:self.toolBar];
    [self.view bringSubviewToFront:self.toolBar];
    
    self.zoomingImageView = [[[ZoomingImageView alloc]initWithFrame:CGRectMake(0, 44, screenBounds.size.width, screenBounds.size.height-88)]autorelease];
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
    [tt release];
    
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
    [imageFiles release];

    [self.zoomingImageView loadImage:[UIImage imageWithContentsOfFile:[kAppDelegate openFile]]];
}

- (void)uploadToDropbox {
    if (![[DBSession sharedSession]isLinked]) {
        [[DBSession sharedSession]linkFromController:self];
    } else {
        [kAppDelegate uploadLocalFile:[kAppDelegate openFile]];
    }
}

- (void)addToTheRoll {
    
    [kAppDelegate showHUDWithTitle:@"Working..."];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];

        NSString *file = [kAppDelegate openFile];
        UIImage *image = [[UIImage alloc]initWithContentsOfFile:file];
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        [image release];
        
        [NSThread sleepForTimeInterval:0.5f];

        dispatch_sync(dispatch_get_main_queue(), ^{
            NSAutoreleasePool *poolTwo = [[NSAutoreleasePool alloc]init];

            NSString *fileName = [file lastPathComponent];
            
            if (fileName.length > 14) {
                fileName = [[fileName substringToIndex:11]stringByAppendingString:@"..."];
            }
            
            UIImageView *checkmark = [[UIImageView alloc]initWithImage:getCheckmarkImage()];
            
            [kAppDelegate hideHUD];
            
            [kAppDelegate showHUDWithTitle:@"Imported"];
            [kAppDelegate setSecondaryTitleOfVisibleHUD:fileName];
            [kAppDelegate setVisibleHudMode:MBProgressHUDModeCustomView];
            [kAppDelegate setVisibleHudCustomView:checkmark];
            [kAppDelegate hideVisibleHudAfterDelay:1.0f];
            [checkmark release];
            [poolTwo release];
        });
        
        [pool release];
    });
}

- (void)close {
    [self dismissModalViewControllerAnimated:YES];
    [[UIApplication sharedApplication]setStatusBarHidden:NO];
    self.view.frame = [[UIScreen mainScreen]applicationFrame];
    [kAppDelegate setOpenFile:nil];
}

- (void)showNoitcaSheet:(id)sender {
    
    if (self.popupQuery && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.popupQuery dismissWithClickedButtonIndex:self.popupQuery.cancelButtonIndex animated:YES];
        self.popupQuery = nil;
        return;
    }
    
    NSString *file = [kAppDelegate openFile];
    NSString *fileName = [file lastPathComponent];

    self.popupQuery = [[[UIActionSheet alloc]initWithTitle:[NSString stringWithFormat:@"What would you like to do with %@?",fileName] completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
        
        if (buttonIndex == 0) {
            [kAppDelegate printFile:file fromView:self.view];
        } else if (buttonIndex == 1) {
            [kAppDelegate sendFileInEmail:file fromViewController:self];
        } else if (buttonIndex == 2) {
            [kAppDelegate showBTController];
        } else if (buttonIndex == 3) {
            [kAppDelegate showFTPUploadController];
        } else if (buttonIndex == 4) {
            [self uploadToDropbox];
        } else if (buttonIndex == 5) {
            if ([MIMEUtils isImageFile:file]) {
                [self addToTheRoll];
            } else {
                NSString *message = [[NSString alloc]initWithFormat:@"Sorry, the file \"%@\" is not an image or is corrupt.",fileName];
                CustomAlertView *av = [[CustomAlertView alloc]initWithTitle:@"Failure Importing Image" message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [av show];
                [av release];
                [message release];
            }
        }
    } cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Print", @"Email File", @"Send Via Bluetooth", @"Upload to Server", @"Upload to Dropbox", @"Add to Photo Library", nil]autorelease];
    
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
    [imageFiles release];
    
    if (lastImage == newImageNumber) {
        [self.nextImg setEnabled:NO];
    }
    
    self.zoomingImageView.zoomScale = self.zoomingImageView.minimumZoomScale;
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
    [imageFiles release];
    
    if (newImageNumber == 0) {
        [self.prevImg setEnabled:NO];
    }
    
    self.zoomingImageView.zoomScale = self.zoomingImageView.minimumZoomScale;
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

- (void)dealloc {
    [self setPopupQuery:nil];
    [self setPrevImg:nil];
    [self setNextImg:nil];
    [self setNavBar:nil];
    [self setToolBar:nil];
    [self setZoomingImageView:nil];
    NSLog(@"%@ dealloc'd", NSStringFromClass([self class]));
    [super dealloc];
}

@end