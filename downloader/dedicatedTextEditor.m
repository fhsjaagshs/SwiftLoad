//
//  dedicatedTextEditor.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 10/31/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import "dedicatedTextEditor.h"

@implementation dedicatedTextEditor

@synthesize theTextView, fontSizeLabel, stepperFontAdjustment, navBar, popupQuery;

- (void)loadView {
    [super loadView];
    
    hasEdited = NO;
    
    self.view.backgroundColor = [UIColor clearColor];
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    self.navBar = [[[CustomNavBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)]autorelease];
    self.navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:[[kAppDelegate openFile]lastPathComponent]];
    topItem.leftBarButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)]autorelease];
    topItem.rightBarButtonItem = [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showActionSheet:)]autorelease];
    [self.navBar pushNavigationItem:topItem animated:NO];
    [self.view addSubview:self.navBar];
    [self.view bringSubviewToFront:self.navBar];
    [topItem release];
    
    self.stepperFontAdjustment = [[[UIStepper alloc]initWithFrame:CGRectMake(0, 0, 94, 27)]autorelease];

    self.theTextView = [[[UITextView alloc]initWithFrame:CGRectMake(0, 44, screenBounds.size.width, screenBounds.size.height-44)]autorelease];
    self.theTextView.delegate = self;
    self.theTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    self.toolBar = [[[CustomToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 44)]autorelease];
    UIBarButtonItem *space = [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]autorelease];
    UIBarButtonItem *hideKeyboard = [[[UIBarButtonItem alloc]initWithTitle:@"Hide" style:UIBarButtonItemStyleBordered target:self action:@selector(dismissKeyboard)]autorelease];
    UIBarButtonItem *stepper = [[[UIBarButtonItem alloc]initWithCustomView:self.stepperFontAdjustment]autorelease];
    self.toolBar.items = [NSArray arrayWithObjects:space, stepper, space, hideKeyboard, nil];
    
    [self.theTextView setInputAccessoryView:self.toolBar];
    
    [self.view addSubview:self.theTextView];
    [self.view bringSubviewToFront:self.theTextView];
    
    self.stepperFontAdjustment.value = 14;
    
    [self registerForKeyboardNotifications];
    [self stepperStepped];
    [self loadText];
}

- (void)saveText {
    if (!theEncoding) {
        theEncoding = NSUTF8StringEncoding;
    }
    
    [self.theTextView.text writeToFile:[kAppDelegate openFile] atomically:YES encoding:theEncoding error:nil];
    [self hideSaveButton];
}

- (NSString *)getStringFromFile {
    
    NSString *filePath = [kAppDelegate openFile];
    
    NSStringEncoding myEncodingToTest[] = { NSUTF8StringEncoding, NSASCIIStringEncoding, NSUTF16BigEndianStringEncoding, NSUTF16LittleEndianStringEncoding, NSUTF16StringEncoding, NSUTF32BigEndianStringEncoding, NSUTF32LittleEndianStringEncoding, NSUTF32StringEncoding, NSNEXTSTEPStringEncoding, NSJapaneseEUCStringEncoding, NSISOLatin1StringEncoding, NSSymbolStringEncoding, NSNonLossyASCIIStringEncoding, NSShiftJISStringEncoding, NSISOLatin2StringEncoding, NSUnicodeStringEncoding, NSWindowsCP1251StringEncoding, NSWindowsCP1252StringEncoding, NSWindowsCP1253StringEncoding, NSWindowsCP1254StringEncoding, NSWindowsCP1250StringEncoding, NSISO2022JPStringEncoding, NSMacOSRomanStringEncoding, NSUTF16BigEndianStringEncoding, NSUTF16LittleEndianStringEncoding, NSUTF32StringEncoding, NSUTF32BigEndianStringEncoding, NSUTF32LittleEndianStringEncoding };
    int howManyEncodings = sizeof(myEncodingToTest)/sizeof(NSStringEncoding);
    
    NSString *stringToReturn = nil;
    
    for (int i = 0; (i < howManyEncodings); i++) {
        
        NSString *testString = [NSString stringWithContentsOfFile:filePath encoding:myEncodingToTest[i] error:nil];

        if (testString.length > 0 && testString != nil) {
            stringToReturn = testString;
            theEncoding = myEncodingToTest[i];
            break;
        }
    }

    return stringToReturn;
}

- (void)showSaveButton {
    if (self.theTextView.isFirstResponder) {
        if (self.toolBar.items.count == 4) {
            UIBarButtonItem *saveChanges = [[[UIBarButtonItem alloc]initWithTitle:@"Save" style:UIBarButtonItemStyleBordered target:self action:@selector(saveText)]autorelease];
            NSMutableArray *items = [[self.toolBar.items mutableCopy]autorelease];
            [items insertObject:saveChanges atIndex:0];
            self.toolBar.items = items;
        }
    }
}

- (void)hideSaveButton {
    if (hasEdited) {
        NSMutableArray *items = [[self.toolBar.items mutableCopy]autorelease];
        [items removeObjectAtIndex:0];
        self.toolBar.items = items;
        hasEdited = NO;
    }
}

- (void)stepperStepped {
    [self.theTextView setFont:[UIFont systemFontOfSize:self.stepperFontAdjustment.value]];
    NSString *newLabel = [NSString stringWithFormat:@"%dpt",(int)self.stepperFontAdjustment.value];
    [self.fontSizeLabel setText:newLabel];
}

- (void)uploadToDropbox {
    if (![[DBSession sharedSession]isLinked]) {
        [[DBSession sharedSession]linkFromController:self];
    } else {
        [kAppDelegate uploadLocalFile:[kAppDelegate openFile]];
    }
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)dismissKeyboard {
    if ([self.theTextView isFirstResponder]) {
        [self.theTextView resignFirstResponder];
    }
}

- (void)close {
    [self dismissKeyboard];
    [self dismissModalViewControllerAnimated:YES];
    [kAppDelegate setOpenFile:nil];
}

- (void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWasShown:(NSNotification*)aNotification {
    CGSize kbSize = [[[aNotification userInfo]objectForKey:UIKeyboardFrameBeginUserInfoKey]CGRectValue].size;
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0, 0, kbSize.height, 0);
    
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication]statusBarOrientation])) {
        contentInsets = UIEdgeInsetsMake(0, 0, kbSize.width, 0);
    }
    
    self.theTextView.contentInset = contentInsets;
    self.theTextView.scrollIndicatorInsets = contentInsets;
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
    self.theTextView.contentInset = UIEdgeInsetsZero;
    self.theTextView.scrollIndicatorInsets = UIEdgeInsetsZero;
}

- (void)textViewDidChange:(UITextView *)textView {
    [self showSaveButton];
    hasEdited = YES;
}

- (void)showActionSheet:(id)sender {
    
    if (self.popupQuery && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.popupQuery dismissWithClickedButtonIndex:self.popupQuery.cancelButtonIndex animated:YES];
        self.popupQuery = nil;
        return;
    }
    
    NSString *file = [kAppDelegate openFile];
    
    UIActionSheet *sheet = [[UIActionSheet alloc]initWithTitle:[NSString stringWithFormat:@"What would you like to do with %@?",[file lastPathComponent]] completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
        if (buttonIndex == 0) {
            [kAppDelegate sendFileInEmail:file fromViewController:self];
        } else if (buttonIndex == 1) {
            [kAppDelegate showBTController];
        } else if (buttonIndex == 2) {
            [kAppDelegate sendStringAsSMS:[NSString stringWithContentsOfFile:file encoding:theEncoding error:nil] fromViewController:self];
        } else if (buttonIndex == 3) {
            [kAppDelegate showFTPUploadController];
        } else if (buttonIndex == 4) {
            [self uploadToDropbox];
        }
    } cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Email File", @"Send Via Bluetooth", @"Send as SMS", @"Upload to Server", @"Upload to Dropbox", nil];
    
    [self setPopupQuery:sheet];
    [sheet release];
    
    self.popupQuery.actionSheetStyle = UIActionSheetStyleBlackTranslucent;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.popupQuery showFromBarButtonItem:(UIBarButtonItem *)sender animated:YES];
    } else {
        [self.popupQuery showInView:self.view];
    }
}

- (void)loadText {
    [self.theTextView setHidden:YES];
    [self.view setBackgroundColor:[UIColor clearColor]];
    [kAppDelegate showHUDWithTitle:@"Loading..."];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
        
        NSString *fileContents = [self getStringFromFile];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSAutoreleasePool *poolTwo = [[NSAutoreleasePool alloc]init];
            [self.theTextView setText:fileContents];
            [self.theTextView setHidden:NO];
            [self.view setBackgroundColor:[UIColor whiteColor]];
            [kAppDelegate hideHUD];
            [poolTwo release];
        });
        
        [pool release];
    });
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (void)dealloc {
    [self setPopupQuery:nil];
    [self setStepperFontAdjustment:nil];
    [self setFontSizeLabel:nil];
    [self setTheTextView:nil];
    [self setNavBar:nil];
    [self setToolBar:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    NSLog(@"%@ dealloc'd", NSStringFromClass([self class]));
    [super dealloc];
}

@end
