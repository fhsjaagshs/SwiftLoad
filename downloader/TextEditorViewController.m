//
//  dedicatedTextEditor.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 10/31/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import "TextEditorViewController.h"

@interface TextEditorViewController () <MFMessageComposeViewControllerDelegate, UITextViewDelegate>

@property (nonatomic, strong) UIActionSheet *popupQuery;
@property (nonatomic, strong) UITextView *theTextView;
@property (nonatomic, strong) ShadowedNavBar *navBar;
@property (nonatomic, strong) ShadowedToolbar *toolBar;

@property (nonatomic, assign) NSStringEncoding theEncoding;
@property (nonatomic, assign) BOOL hasEdited;

@end

@implementation TextEditorViewController

- (void)loadView {
    [super loadView];
    
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    self.navBar = [[ShadowedNavBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)];
    self.navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:[[kAppDelegate openFile]lastPathComponent]];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showActionSheet:)];
    [self.navBar pushNavigationItem:topItem animated:NO];
    [self.view addSubview:self.navBar];
    [self.view bringSubviewToFront:self.navBar];

    self.theTextView = [[UITextView alloc]initWithFrame:CGRectMake(0, 44, screenBounds.size.width, screenBounds.size.height-44)];
    self.theTextView.delegate = self;
    self.theTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    self.toolBar = [[ShadowedToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 44)];
    UIBarButtonItem *space = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *hideKeyboard = [[UIBarButtonItem alloc]initWithTitle:@"Hide" style:UIBarButtonItemStyleBordered target:self action:@selector(dismissKeyboard)];
    self.toolBar.items = @[space, hideKeyboard];
    
    [self.theTextView setInputAccessoryView:self.toolBar];
    
    [self.view addSubview:self.theTextView];
    [self.view bringSubviewToFront:self.theTextView];
    
    [self registerForKeyboardNotifications];
    [self loadText];
}

- (void)saveText {
    if (!_theEncoding) {
        self.theEncoding = NSUTF8StringEncoding;
    }
    
    [_theTextView.text writeToFile:[kAppDelegate openFile] atomically:YES encoding:_theEncoding error:nil];
    [self hideSaveButton];
}

- (NSString *)getStringFromFile {    
    NSStringEncoding encodingsToTest[] = { NSUTF8StringEncoding, NSASCIIStringEncoding, NSUTF16BigEndianStringEncoding, NSUTF16LittleEndianStringEncoding, NSUTF16StringEncoding, NSUTF32BigEndianStringEncoding, NSUTF32LittleEndianStringEncoding, NSUTF32StringEncoding, NSNEXTSTEPStringEncoding, NSJapaneseEUCStringEncoding, NSISOLatin1StringEncoding, NSSymbolStringEncoding, NSNonLossyASCIIStringEncoding, NSShiftJISStringEncoding, NSISOLatin2StringEncoding, NSUnicodeStringEncoding, NSWindowsCP1251StringEncoding, NSWindowsCP1252StringEncoding, NSWindowsCP1253StringEncoding, NSWindowsCP1254StringEncoding, NSWindowsCP1250StringEncoding, NSISO2022JPStringEncoding, NSMacOSRomanStringEncoding, NSUTF16BigEndianStringEncoding, NSUTF16LittleEndianStringEncoding, NSUTF32StringEncoding, NSUTF32BigEndianStringEncoding, NSUTF32LittleEndianStringEncoding };
    
    int numberOfEncodings = sizeof(encodingsToTest)/sizeof(NSStringEncoding);
    
    NSString *stringToReturn = nil;
    
    NSString *filePath = [kAppDelegate openFile];
    
    for (int i = 0; i < numberOfEncodings; i++) {
        
        NSStringEncoding currentEndcoding = encodingsToTest[i];
        
        NSString *testString = [NSString stringWithContentsOfFile:filePath encoding:currentEndcoding error:nil];

        if (testString.length > 0 && testString != nil) {
            stringToReturn = testString;
            self.theEncoding = currentEndcoding;
            break;
        }
    }

    return stringToReturn;
}

- (void)showSaveButton {
    if (_theTextView.isFirstResponder) {
        if (_toolBar.items.count == 2) {
            UIBarButtonItem *saveChanges = [[UIBarButtonItem alloc]initWithTitle:@"Save" style:UIBarButtonItemStyleBordered target:self action:@selector(saveText)];
            NSMutableArray *items = [_toolBar.items mutableCopy];
            [items insertObject:saveChanges atIndex:0];
            _toolBar.items = items;
        }
    }
}

- (void)hideSaveButton {
    if (_hasEdited) {
        NSMutableArray *items = [_toolBar.items mutableCopy];
        [items removeObjectAtIndex:0];
        _toolBar.items = items;
        self.hasEdited = NO;
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
    BOOL isLandscape = UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication]statusBarOrientation]);
    CGSize kbSize = [[[aNotification userInfo]objectForKey:UIKeyboardFrameBeginUserInfoKey]CGRectValue].size;
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0, 0, isLandscape?kbSize.width:kbSize.height, 0);
    
    self.theTextView.contentInset = contentInsets;
    self.theTextView.scrollIndicatorInsets = contentInsets;
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
    self.theTextView.contentInset = UIEdgeInsetsZero;
    self.theTextView.scrollIndicatorInsets = UIEdgeInsetsZero;
}

- (void)textViewDidChange:(UITextView *)textView {
    [self showSaveButton];
    self.hasEdited = YES;
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
            [BluetoothTask sendFile:file];
        } else if (buttonIndex == 2) {
            [kAppDelegate sendStringAsSMS:[NSString stringWithContentsOfFile:file encoding:_theEncoding error:nil] fromViewController:self];
        } else if (buttonIndex == 3) {
            [kAppDelegate uploadLocalFile:[kAppDelegate openFile] fromViewController:self];
        }
    } cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Email File", @"Send Via Bluetooth", @"Send as SMS", @"Upload to Dropbox", nil];
    
    [self setPopupQuery:sheet];
    
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
        @autoreleasepool {
        
            NSString *fileContents = [self getStringFromFile];
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                @autoreleasepool {
                    [self.theTextView setText:fileContents];
                    [self.theTextView setHidden:NO];
                    [self.view setBackgroundColor:[UIColor whiteColor]];
                    [kAppDelegate hideHUD];
                }
            });
        
        }
    });
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end
