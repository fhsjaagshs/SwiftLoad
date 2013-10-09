//
//  dedicatedTextEditor.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 10/31/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import "TextEditorViewController.h"

@interface TextEditorViewController () <UITextViewDelegate>

@property (nonatomic, strong) UIActionSheet *popupQuery;
@property (nonatomic, strong) UITextView *theTextView;
@property (nonatomic, strong) UINavigationBar *navBar;
@property (nonatomic, strong) UIToolbar *toolBar;

@property (nonatomic, assign) NSStringEncoding theEncoding;
@property (nonatomic, assign) BOOL hasEdited;

@end

@implementation TextEditorViewController

- (void)loadView {
    [super loadView];

    CGRect screenBounds = [[UIScreen mainScreen]bounds];
    self.navBar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 64)];
    _navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:[[kAppDelegate openFile]lastPathComponent]];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showActionSheet:)];
    [_navBar pushNavigationItem:topItem animated:NO];
    [self.view addSubview:_navBar];

    self.toolBar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 44)];
    UIBarButtonItem *space = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *hideKeyboard = [[UIBarButtonItem alloc]initWithTitle:@"Hide" style:UIBarButtonItemStyleBordered target:self action:@selector(dismissKeyboard)];
    _toolBar.items = @[space, hideKeyboard];
    
    self.theTextView = [[UITextView alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, screenBounds.size.height)];
    _theTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _theTextView.delegate = self;
    _theTextView.inputAccessoryView = _toolBar;
    _theTextView.tintColor = [UIColor blueColor];
    _theTextView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
    _theTextView.scrollIndicatorInsets = _theTextView.contentInset;
    [self.view addSubview:_theTextView];
    [self.view bringSubviewToFront:_theTextView];
    
    [self.view bringSubviewToFront:_navBar];
    
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

- (void)dismissKeyboard {
    if ([_theTextView isFirstResponder]) {
        [_theTextView resignFirstResponder];
    }
}

- (void)close {
    __weak TextEditorViewController *weakself = self;
    [self dismissViewControllerAnimated:YES completion:^{
        [weakself dismissKeyboard];
        [kAppDelegate setOpenFile:nil];
    }];
}

- (void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWasShown:(NSNotification*)aNotification {
    BOOL isLandscape = UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication]statusBarOrientation]);
    CGSize kbSize = [[aNotification userInfo][UIKeyboardFrameBeginUserInfoKey]CGRectValue].size;
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(_theTextView.contentInset.top, 0, isLandscape?kbSize.width:kbSize.height, 0);
    
    _theTextView.contentInset = contentInsets;
    _theTextView.scrollIndicatorInsets = contentInsets;
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
    _theTextView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
    _theTextView.scrollIndicatorInsets = _theTextView.contentInset;
}

- (void)textViewDidChange:(UITextView *)textView {
    [self showSaveButton];
    self.hasEdited = YES;
}

- (void)showActionSheet:(id)sender {
    if (_popupQuery && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [_popupQuery dismissWithClickedButtonIndex:_popupQuery.cancelButtonIndex animated:YES];
        self.popupQuery = nil;
        return;
    }

    self.popupQuery = [[UIActionSheet alloc]initWithTitle:[NSString stringWithFormat:@"What would you like to do with %@?",kAppDelegate.openFile.lastPathComponent] completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
        NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
        
        if ([title isEqualToString:kActionButtonNameEmail]) {
            [kAppDelegate sendFileInEmail:kAppDelegate.openFile];
        } else if ([title isEqualToString:kActionButtonNameP2P]) {
            [[BTManager shared]sendFileAtPath:kAppDelegate.openFile];
        } else if ([title isEqualToString:kActionButtonNameDBUpload]) {
            [[TaskController sharedController]addTask:[DropboxUpload uploadWithFile:kAppDelegate.openFile]];
        }
    } cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:kActionButtonNameEmail, kActionButtonNameP2P, kActionButtonNameDBUpload, nil];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [_popupQuery showFromBarButtonItem:(UIBarButtonItem *)sender animated:YES];
    } else {
        [_popupQuery showInView:self.view];
    }
}

- (void)loadText {
    _theTextView.hidden = YES;
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[kAppDelegate window] animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.labelText = @"Loading...";
    
    __weak TextEditorViewController *weakself = self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
        
            NSString *fileContents = [weakself getStringFromFile];
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                @autoreleasepool {
                    [weakself.theTextView setText:fileContents];
                    [weakself.theTextView setHidden:NO];
                    [weakself.view setBackgroundColor:[UIColor whiteColor]];
                    [hud hide:YES];
                }
            });
        
        }
    });
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end
