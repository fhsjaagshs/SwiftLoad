//
//  pictureView.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 10/27/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import "PictureViewController.h"

@interface PictureViewController ()

@property (nonatomic, strong) UIActionSheet *popupQuery;
@property (nonatomic, strong) ZoomingImageView *zoomingImageView;
@property (nonatomic, strong) UIBarButtonItem *prevImg;
@property (nonatomic, strong) UIBarButtonItem *nextImg;
@property (nonatomic, strong) UINavigationBar *navBar;
@property (nonatomic, strong) UIToolbar *toolBar;

@property (nonatomic, assign) int imageNumber;

@end

@implementation PictureViewController

- (void)loadView {
    [super loadView];
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    
    self.navBar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)];
    _navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:[[kAppDelegate openFile]lastPathComponent]];
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showActionSheet:)];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    [_navBar pushNavigationItem:topItem animated:YES];
    [self.view addSubview:_navBar];
    [self.view bringSubviewToFront:_navBar];
    
    self.toolBar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, screenBounds.size.height-44, screenBounds.size.width, 44)];
    _toolBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    
    UIBarButtonItem *space = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    self.nextImg = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"ArrowRight"] style:UIBarButtonItemStylePlain target:self action:@selector(nextImage)];
    self.prevImg = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"ArrowLeft"] style:UIBarButtonItemStylePlain target:self action:@selector(previousImage)];
    
    self.toolBar.items = @[space,_prevImg,space,_nextImg,space];
    [self.view addSubview:_toolBar];
    [self.view bringSubviewToFront:_toolBar];
    
    self.zoomingImageView = [[ZoomingImageView alloc]initWithFrame:CGRectMake(0, 44, screenBounds.size.width, screenBounds.size.height-88)];
    _zoomingImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.view addSubview:_zoomingImageView];
    [self.view bringSubviewToFront:_zoomingImageView];
    
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication]statusBarOrientation])) {
            [_toolBar setHidden:YES];
            [_navBar setHidden:YES];
            [[UIApplication sharedApplication]setStatusBarHidden:YES];
            self.view.frame = [[UIScreen mainScreen]bounds];
            _zoomingImageView.frame = self.view.frame;
        }
    }
    
    UITapGestureRecognizer *tt = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(imageViewWasDoubleTapped:)];
    [tt setNumberOfTapsRequired:2];
    [tt setNumberOfTouchesRequired:1];
    [_zoomingImageView addGestureRecognizer:tt];
    
    NSArray *imageFiles = [self imageFiles];
    
    self.imageNumber = [imageFiles indexOfObject:[kAppDelegate openFile]];
    
    if (imageFiles.count == 1) {
        [_nextImg setEnabled:NO];
        [_prevImg setEnabled:NO];
    }
    
    if (_imageNumber == 0) {
        [_prevImg setEnabled:NO];
    }
    
    if (_imageNumber == imageFiles.count-1) {
        [_nextImg setEnabled:NO];
    }

    [_zoomingImageView loadImage:[UIImage imageWithContentsOfFile:[kAppDelegate openFile]]];
    
    [self adjustViewsForiOS7];
}

- (NSArray *)imageFiles {
    NSString *currentDir = [kAppDelegate managerCurrentDir];
    NSArray *filesOfDir = [[[NSFileManager defaultManager]contentsOfDirectoryAtPath:currentDir error:nil]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSMutableArray *imageFiles = [NSMutableArray arrayWithCapacity:filesOfDir.count];
    
    for (NSString *object in filesOfDir) {
        NSString *newObject = [currentDir stringByAppendingPathComponent:object];
        if ([MIMEUtils isImageFile:newObject]) {
            [imageFiles addObject:newObject];
        }
    }
    
    return imageFiles;
}

- (void)addToTheRoll {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[kAppDelegate window] animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.labelText = @"Working...";
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            UIImage *image = [UIImage imageWithContentsOfFile:[kAppDelegate openFile]];
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
            
            [NSThread sleepForTimeInterval:0.5f];

            dispatch_sync(dispatch_get_main_queue(), ^{
                @autoreleasepool {
                    NSString *fileName = [[kAppDelegate openFile]lastPathComponent];
                    
                    if (fileName.length > 14) {
                        fileName = [[fileName substringToIndex:11]stringByAppendingString:@"..."];
                    }
                    
                    hud.labelText = @"Imported";
                    hud.detailsLabelText = fileName;
                    
                    [hud hide:YES afterDelay:1.0f];
                }
            });
        }
    });
}

- (void)close {
    [self dismissViewControllerAnimated:YES completion:nil];
    [[UIApplication sharedApplication]setStatusBarHidden:NO];
    self.view.frame = [[UIScreen mainScreen]applicationFrame];
    [kAppDelegate setOpenFile:nil];
}

// Action in reverse is Noitca
- (void)showActionSheet:(id)sender {
    
    if (_popupQuery && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [_popupQuery dismissWithClickedButtonIndex:_popupQuery.cancelButtonIndex animated:YES];
        self.popupQuery = nil;
        return;
    }
    
    NSString *file = [kAppDelegate openFile];
    NSString *fileName = [file lastPathComponent];

    self.popupQuery = [[UIActionSheet alloc]initWithTitle:[NSString stringWithFormat:@"What would you like to do with %@?",fileName] completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
        
        if (buttonIndex == 0) {
            [kAppDelegate printFile:file fromView:self.view];
        } else if (buttonIndex == 1) {
            [kAppDelegate sendFileInEmail:file];
        } else if (buttonIndex == 2) {
            BluetoothTask *task = [BluetoothTask taskWithFile:[kAppDelegate openFile]];
            [[TaskController sharedController]addTask:task];
        } else if (buttonIndex == 3) {
            DropboxUpload *task = [DropboxUpload uploadWithFile:[kAppDelegate openFile]];
            [[TaskController sharedController]addTask:task];
        } else if (buttonIndex == 4) {
            if ([MIMEUtils isImageFile:file]) {
                [self addToTheRoll];
            } else {
                NSString *message = [[NSString alloc]initWithFormat:@"Swift was unable to add \"%@\" to the camera roll.",fileName];
                [UIAlertView showAlertWithTitle:@"Import Failure" andMessage:message];
            }
        }
    } cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Print", @"Email File", @"Send Via Bluetooth", @"Upload to Dropbox", @"Add to Photo Library", nil];
    
    _popupQuery.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [_popupQuery showFromBarButtonItem:(UIBarButtonItem *)sender animated:YES];
    } else {
        [_popupQuery showInView:self.view];
    }
}

- (void)nextImage {
    [_prevImg setEnabled:YES];
    
    NSArray *imageFiles = [self imageFiles];

    self.imageNumber += 1;

    NSString *newImagePath = imageFiles[_imageNumber];
    
    if (imageFiles.count-1 == _imageNumber) {
        [_nextImg setEnabled:NO];
    }
    
    [_zoomingImageView loadImage:[UIImage imageWithContentsOfFile:newImagePath]];

    [kAppDelegate setOpenFile:newImagePath];
    _navBar.topItem.title = newImagePath.lastPathComponent;
}

- (void)previousImage {
    [_nextImg setEnabled:YES];
    
    NSArray *imageFiles = [self imageFiles];
    
    self.imageNumber -= 1;
    
    if (_imageNumber == 0) {
        [_prevImg setEnabled:NO];
    }

    NSString *newImagePath = imageFiles[_imageNumber];
    
    [_zoomingImageView loadImage:[UIImage imageWithContentsOfFile:newImagePath]];

    [kAppDelegate setOpenFile:newImagePath];
    _navBar.topItem.title = newImagePath.lastPathComponent;
}

- (void)imageViewWasDoubleTapped:(UIGestureRecognizer *)rec {
    if (_zoomingImageView.zoomScale > _zoomingImageView.minimumZoomScale) {
        [_zoomingImageView zoomOut];
    } else {
        [_zoomingImageView zoomToPoint:[rec locationInView:self.view] withScale:_zoomingImageView.maximumZoomScale animated:YES];
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        [_toolBar setHidden:NO];
        [_navBar setHidden:NO];
    } else {
        [_toolBar setHidden:YES];
        [_navBar setHidden:YES];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication]statusBarOrientation])) {
        [[UIApplication sharedApplication]setStatusBarHidden:NO];
        self.view.frame = [[UIScreen mainScreen]applicationFrame];
        _zoomingImageView.frame = CGRectMake(0, 44, self.view.bounds.size.width, self.view.bounds.size.height-88);
    } else {
        [[UIApplication sharedApplication]setStatusBarHidden:YES];
        self.view.frame = [[UIScreen mainScreen]bounds];
        _zoomingImageView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    }
    
    [_zoomingImageView resetImage];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

@end
