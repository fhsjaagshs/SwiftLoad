//
//  pictureView.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 10/27/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MyFilesViewController.h"
#import "pictureView.h"
#import "fileInfo.h"

@implementation pictureView

@synthesize sessionController = _sessionController;

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        NSString *filePath = [[NSUserDefaults standardUserDefaults]objectForKey:@"cellNameFileKey"];
        NSData *file = [NSData dataWithContentsOfFile:filePath];
        NSString *fileName = [filePath lastPathComponent];
        NSArray *array = [NSArray arrayWithObjects:fileName, file, nil];
        NSData *finalData = [NSKeyedArchiver archivedDataWithRootObject:array];
        [_sessionController sendDataToAllPeers:finalData];
        file = nil;
        array = nil;
        finalData = nil;
        // remember to nil it out
    }
}

- (void)createSession:(GKSession *)session {
    self.sessionController = [BKSessionController sessionControllerWithSession:session];
    _sessionController.delegate = self;
}

- (void)peerPickerController:(GKPeerPickerController *) picker didConnectPeer:(NSString *) peerID toSession:(GKSession *) session{
    
    UIAlertView *av = [[[UIAlertView alloc]initWithTitle:@"Connected" message:@"Would you like to send the file?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Send file", nil]autorelease];
    [av show];
    
    [self createSession:session];
    
    //Cleanups
    picker.delegate = nil;
    [picker dismiss];
}

- (void)peerPickerControllerDidCancel:(GKPeerPickerController *) picker {
    
	picker.delegate = nil;
}

- (void)sessionControllerSenderDidFinishSendingData:(NSNotification *)aNotification {
    [_sessionController.session disconnectFromAllPeers];
    _sessionController.session.delegate = nil;
    _sessionController.session = nil;
    _sessionController = nil;
}

- (void)resetTheTransform {
    CGAffineTransform tr = theImageView.transform;
    CGFloat negAngle = (360-(atan2(tr.b, tr.a))); // Get opposite rotation
    tr = CGAffineTransformMakeRotation(negAngle); // Undo opposite rotation
    theImageView.transform = tr; // Set it
    CGFloat newTX = 0;
    CGFloat newTY = 0;
    theImageView.transform = CGAffineTransformMakeTranslation(newTX, newTY); // undo translation
    
    [theImageView setTransformFromOutside:theImageView.transform];
    [resetButton setEnabled:NO];
}

- (void)printFile {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
    NSString *path = [[NSUserDefaults standardUserDefaults] objectForKey:@"cellNameFileKey"];
    NSData *myData = [NSData dataWithContentsOfFile:path];
    
    UIPrintInteractionController *pic = [UIPrintInteractionController sharedPrintController];
    
    pic.delegate = self;
    
    UIPrintInfo *printInfo = [UIPrintInfo printInfo];
    printInfo.outputType = UIPrintInfoOutputGeneral;
    printInfo.jobName = [path lastPathComponent];
    printInfo.duplex = UIPrintInfoDuplexLongEdge;
    pic.printInfo = printInfo;
    pic.showsPageRange = YES;
    pic.printingItem = myData;
    
    void (^completionHandler)(UIPrintInteractionController *, BOOL, NSError *) = ^(UIPrintInteractionController *pic, BOOL completed, NSError *error) {
        //self.content = nil;
        if (!completed && error) {
            NSLog(@"FAILED! due to error in domain %@ with error code %u", error.domain, error.code);
        } 
    };
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [pic presentFromRect:CGRectMake(716, 967, 44, 37) inView:self.view animated:YES completionHandler:completionHandler];
    } else {
        [pic presentAnimated:YES completionHandler:completionHandler];
    }
    [pool release];
}

- (void)addToTheRoll {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *file = [[NSUserDefaults standardUserDefaults]objectForKey:@"cellNameFileKey"];
    NSString *fileName = [file lastPathComponent];
    UIImage *image = [[[UIImage alloc] initWithContentsOfFile:file]autorelease];
    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    MBProgressHUD *HUD2 = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD2];
    [self.view bringSubviewToFront:HUD2];
    UIImageView *checkmark = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]]autorelease];
    HUD2.customView = checkmark;
    HUD2.mode = MBProgressHUDModeCustomView;
    HUD2.labelText = @"Imported";
    HUD2.detailsLabelText = fileName;
    [HUD2 showWhileExecuting:@selector(sleepMe) onTarget:self withObject:nil animated:YES];
    [HUD2 release];
    [pool release];
}

- (void)sleepMe {
    sleep(1);
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    // After pressing the add to the roll button, I get a leak with malloc for 64 bytes
    
    NSString *file = [[NSUserDefaults standardUserDefaults] objectForKey:@"cellNameFileKey"];
    NSString *fileName = [file lastPathComponent];
    NSURL *fileUrl = [NSURL fileURLWithPath:file];
    NSURLRequest *fileUrlRequest = [[[NSURLRequest alloc] initWithURL:fileUrl cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:.1]autorelease];
    
    NSURLResponse* response = nil;
    [NSURLConnection sendSynchronousRequest:fileUrlRequest returningResponse:&response error:nil];
    
    NSString *mimeType = [response MIMEType];
    NSString *textFile = [mimeType substringToIndex:4];
    BOOL anImage = [textFile isEqualToString:@"imag"];
    
    if (buttonIndex == 0) {
        BOOL sendsMail = [MFMailComposeViewController canSendMail];
        if (sendsMail == NO) {
            UIAlertView *av = [[[UIAlertView alloc]initWithTitle:@"Mail Unavailable" message:@"In order to use this functionality, you must set up an email account in Settings." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]autorelease];
            [av show];
        } else if (sendsMail == YES) {
            NSString *ext = [file pathExtension];
            MFMailComposeViewController *controller = [[[MFMailComposeViewController alloc] init]autorelease];
            controller.mailComposeDelegate = self;
            [controller setSubject:@"Your file"];
            NSData *myData = [[[NSData alloc] initWithContentsOfFile:file]autorelease];   
            [controller addAttachmentData:myData mimeType:ext fileName:fileName];
            [controller setMessageBody:@"" isHTML:NO];
            [self presentModalViewController:controller animated:YES];
        }
    } else if (buttonIndex == 1) {
        if (anImage == YES) {
            HUD = [[MBProgressHUD alloc] initWithView:self.view];
            [self.view addSubview:HUD];
            [self.view bringSubviewToFront:HUD];
            HUD.labelText = @"Working";
            [HUD showWhileExecuting:@selector(addToTheRoll) onTarget:self withObject:nil animated:YES];
            [HUD release];
        } else {
            NSString *message = [NSString stringWithFormat:@"Sorry, the file \"%@\" is not an image or is corrupt.",fileName];
            UIAlertView *av = [[[UIAlertView alloc] initWithTitle:@"Failure Importing Image" message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil]autorelease];
            [av show];
        }
    } else if (buttonIndex == 2) {
        fileInfo *theFileInfo = [[[fileInfo alloc] initWithNibName:@"fileInfo" bundle:nil]autorelease];
        theFileInfo.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [self presentModalViewController:theFileInfo animated:YES];
    } else if (buttonIndex == 3) {
        [NSThread detachNewThreadSelector:@selector(printFile) toTarget:self withObject:nil];
    } else if (buttonIndex == 4) {
        GKPeerPickerController *peerPicker = [[GKPeerPickerController alloc] init];
        peerPicker.delegate = self;
        peerPicker.connectionTypesMask = GKPeerPickerConnectionTypeNearby;
        [peerPicker show]; 
    }
}


- (IBAction)close:(id)sender {
    NSString *file = [[NSUserDefaults standardUserDefaults]objectForKey:@"cellNameFileKey"];
    NSString *newName = [file stringByAppendingString:@"ghg"];
    [[NSFileManager defaultManager]moveItemAtPath:file toPath:newName error:nil];
    [[NSFileManager defaultManager]moveItemAtPath:newName toPath:file error:nil];
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)showActionSheet:(id)sender {
    NSString *file = [[NSUserDefaults standardUserDefaults] objectForKey:@"cellNameFileKey"];
    NSString *fileName = [file lastPathComponent];
    NSString *message = [NSString stringWithFormat:@"What would you like to do with %@?",fileName];
    UIActionSheet *popupQuery = [[[UIActionSheet alloc] initWithTitle:message delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Email File", @"Add to Photo Library", @"More Information", @"Print", @"Send Via Bluetooth", nil]autorelease];
    popupQuery.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [popupQuery showInView:self.view];
}

- (void)updateName {
    [titleOfFile setText:[[[NSUserDefaults standardUserDefaults]objectForKey:@"cellNameFileKey"] lastPathComponent]];
}

- (void)invalidateMyTimer {
    if (timer == [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateName) userInfo:nil repeats:YES]) {
        [timer invalidate];
        [timer release];
    }
}

- (IBAction)nextImage:(id)sender {
    
    // reset the transformation
    [self resetTheTransform];
    
    // reenable the back button
    [prevImg setEnabled:YES];
    
    // Set up paths
    NSString *libDir = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *imageListPlist = [libDir stringByAppendingPathComponent:@"imagelist.plist"];
    
    // Get the old values
    int oldImageNumber = [[[NSUserDefaults standardUserDefaults]objectForKey:@"imageNumber"]intValue];
    
    // Set up the images array
    NSMutableArray *imageFiles = [NSMutableArray arrayWithContentsOfFile:imageListPlist];
    
    // get the new image
    int newImageNumber = oldImageNumber+1;
    NSString *newImagePath = [imageFiles objectAtIndex:newImageNumber];
    UIImage *theImage = [UIImage imageWithContentsOfFile:newImagePath];
    
    // Make sure the image file exists
    int lastImage = [imageFiles indexOfObject:[imageFiles lastObject]];
    
    if (lastImage == newImageNumber) {
        [nextImg setEnabled:NO];
    }
    
    // set the image
    [theImageView setImage:theImage];
    
    // set up the content view mode
    if ((theImageView.image.size.height > theImageView.frame.size.height) || (theImageView.image.size.width > theImageView.frame.size.width)) {
        [theImageView setContentMode:UIViewContentModeScaleAspectFit];
    } else {
        [theImageView setContentMode:UIViewContentModeCenter];
    }
    
    // Set up the new NSUserDefaults keys
    NSString *imageNumberString = [NSString stringWithFormat:@"%d",newImageNumber];;
    [[NSUserDefaults standardUserDefaults]setObject:newImagePath forKey:@"cellNameFileKey"];
    [[NSUserDefaults standardUserDefaults]setObject:imageNumberString forKey:@"imageNumber"];
}

- (IBAction)previousImage:(id)sender {
    
    // reset the transformation
    [self resetTheTransform];
    
    // reenable the next button
    [nextImg setEnabled:YES];
    
    // Set up paths
    NSString *libDir = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *imageListPlist = [libDir stringByAppendingPathComponent:@"imagelist.plist"];
    
    // Get the old values
    int oldImageNumber = [[[NSUserDefaults standardUserDefaults]objectForKey:@"imageNumber"]intValue];
    
    // Set up the images array
    NSMutableArray *imageFiles = [NSMutableArray arrayWithContentsOfFile:imageListPlist];
    
    // get the new image
    int newImageNumber = oldImageNumber-1;
    NSString *newImagePath = [imageFiles objectAtIndex:newImageNumber];
    UIImage *theImage = [UIImage imageWithContentsOfFile:newImagePath];
    
    // Make sure the image file exists
    
    if (newImageNumber == 0) {
        [prevImg setEnabled:NO];
    }
    // set the image
    [theImageView setImage:theImage];
    
    // set the content view
    if ((theImageView.image.size.height > theImageView.frame.size.height) || (theImageView.image.size.width > theImageView.frame.size.width)) {
        [theImageView setContentMode:UIViewContentModeScaleAspectFit];
    } else {
        [theImageView setContentMode:UIViewContentModeCenter];
    }
    
    // Set up the new NSUserDefaults keys
    NSString *imageNumberString = [NSString stringWithFormat:@"%d",newImageNumber];;
    [[NSUserDefaults standardUserDefaults]setObject:newImagePath forKey:@"cellNameFileKey"];
    [[NSUserDefaults standardUserDefaults]setObject:imageNumberString forKey:@"imageNumber"];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self = [super initWithNibName:@"pictureView~iPad" bundle:nibBundleOrNil];
    } else {
        self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    }
    
    if (self) {
        // Custom initialization
    }
    return self;
}

- (IBAction)resetTransform:(id)sender {
    [self resetTheTransform];
}

- (IBAction)setTheResetButtonEnabled:(id)sender {
    [resetButton setEnabled:YES];
}

/*- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint location = [touch locationInView:self.view];
    CGRect frame = theImageView.frame;
    
    if (
}*/

/*- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    
	CGPoint location = [touch locationInView:self.view];
 //   CGRect imgViewFrame = theImageView.frame;
    CGRect nvFrame = navigationView.frame;
    
    if (CGRectContainsPoint(nvFrame, location)) {
        
        CGRect leftHalf = CGRectMake(navigationView.frame.origin.x, navigationView.frame.origin.y, (navigationView.frame.size.width/2), navigationView.frame.size.height);
        CGFloat midX = CGRectGetMidX(navigationView.frame);
        CGRect rightHalf = CGRectMake(midX, navigationView.frame.origin.y, (navigationView.frame.size.width/2), navigationView.frame.size.height);
        
        if (CGRectContainsPoint(leftHalf, location) && [prevImg isEnabled]) {
            
            [self performSelector:@selector(previousImage:)];
            
        } else if (CGRectContainsPoint(rightHalf, location) && [nextImg isEnabled]) {
            
            [self performSelector:@selector(nextImage:)];
            
        }
    } 
}*/

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)imageViewWasTouched:(TouchImageView *)touchImageView {
    [resetButton setEnabled:YES];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [theImageView setUp];
    theImageView.delegate = self;
    
    NSString *currentDir = [[NSUserDefaults standardUserDefaults]objectForKey:@"currentDir"];
    NSArray *filesOfDir = [NSArray arrayWithArray:[[NSFileManager defaultManager]contentsOfDirectoryAtPath:currentDir error:nil]];
    NSMutableArray *imageFiles = [[[NSMutableArray alloc]init]autorelease];
    
    for (NSString *object in filesOfDir) {
        NSString *newObject = [currentDir stringByAppendingPathComponent:object];
        BOOL png = [[newObject pathExtension] isEqualToString:@"png"];
        BOOL jpeg = [[newObject pathExtension] isEqualToString:@"jpeg"];
        BOOL jpg = [[newObject pathExtension] isEqualToString:@"jpg"];
        BOOL tiff = [[newObject pathExtension] isEqualToString:@"tiff"];
        if (png || jpeg || tiff || jpg) {
            [imageFiles addObject:newObject];
        }
    }
    NSString *libDir = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *imageListPlist = [libDir stringByAppendingPathComponent:@"imagelist.plist"];
    if (![[NSFileManager defaultManager]fileExistsAtPath:imageListPlist]) {
        [[NSFileManager defaultManager]createFileAtPath:imageListPlist contents:nil attributes:nil];
    }
    
    [imageFiles writeToFile:imageListPlist atomically:YES];
    NSString *file = [[NSUserDefaults standardUserDefaults] objectForKey:@"cellNameFileKey"];
    int numberInArray = [imageFiles indexOfObject:file];
    if ([imageFiles count] == 1) {
        [nextImg setEnabled:NO];
        [prevImg setEnabled:NO];
    }
    
    if (numberInArray == 0) {
        [prevImg setEnabled:NO];
    }
    
    if (numberInArray == [imageFiles indexOfObject:[imageFiles lastObject]]) {
        [nextImg setEnabled:NO];
    }
    
    NSString *imageNumber = [NSString stringWithFormat:@"%d",numberInArray];;
    [[NSUserDefaults standardUserDefaults]setObject:imageNumber forKey:@"imageNumber"];
    UIImage *theImage = [UIImage imageWithContentsOfFile:file];
    [theImageView setImage:theImage];
    
        if ((theImageView.image.size.height > theImageView.frame.size.height) || (theImageView.image.size.width > theImageView.frame.size.width)) {
            [theImageView setContentMode:UIViewContentModeScaleAspectFit];
        } else {
            [theImageView setContentMode:UIViewContentModeCenter];
        }
    
    timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateName) userInfo:nil repeats:YES];
    [timer fire];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)dealloc {
    [resetButton release];
    self.sessionController.session = nil;
    self.sessionController = nil;
    [self invalidateMyTimer];
    [prevImg release];
    [nextImg release];
    [theImageView release];
    [navigationView release];
    [super dealloc];
}


@end
