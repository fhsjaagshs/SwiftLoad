//
//  dedicatedTextEditor.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 10/31/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import "TextEditorViewController.h"

@interface TextEditorViewController () <UITextViewDelegate>

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
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:self.openFile.lastPathComponent];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    topItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showActionSheet:)];
    [_navBar pushNavigationItem:topItem animated:NO];
    [self.view addSubview:_navBar];

    self.toolBar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 44)];
    UIBarButtonItem *space = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *hideKeyboard = [[UIBarButtonItem alloc]initWithTitle:@"Hide" style:UIBarButtonItemStyleBordered target:self action:@selector(dismissKeyboard)];
    _toolBar.items = @[space, hideKeyboard];
    
    self.theTextView = [[UITextView alloc]initWithFrame:screenBounds];
    _theTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _theTextView.delegate = self;
    _theTextView.inputAccessoryView = _toolBar;
    _theTextView.tintColor = [UIColor blueColor];
    _theTextView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
    _theTextView.scrollIndicatorInsets = _theTextView.contentInset;
    _theTextView.clipsToBounds = NO;
    [self.view addSubview:_theTextView];
    [self.view bringSubviewToFront:_theTextView];
    
    [self.view bringSubviewToFront:_navBar];
    
    [self registerForKeyboardNotifications];
    [self loadText];
    _theTextView.contentOffset = CGPointMake(0, -64);
}

- (void)saveText {
    if (!_theEncoding) {
        self.theEncoding = NSUTF8StringEncoding;
    }
    
    [_theTextView.text writeToFile:self.openFile atomically:YES encoding:_theEncoding error:nil];
    [self hideSaveButton];
}

- (NSString *)getStringFromFile {    
    NSStringEncoding encodingsToTest[] = { NSUTF8StringEncoding, NSASCIIStringEncoding, NSUTF16BigEndianStringEncoding, NSUTF16LittleEndianStringEncoding, NSUTF16StringEncoding, NSUTF32BigEndianStringEncoding, NSUTF32LittleEndianStringEncoding, NSUTF32StringEncoding, NSNEXTSTEPStringEncoding, NSJapaneseEUCStringEncoding, NSISOLatin1StringEncoding, NSSymbolStringEncoding, NSNonLossyASCIIStringEncoding, NSShiftJISStringEncoding, NSISOLatin2StringEncoding, NSUnicodeStringEncoding, NSWindowsCP1251StringEncoding, NSWindowsCP1252StringEncoding, NSWindowsCP1253StringEncoding, NSWindowsCP1254StringEncoding, NSWindowsCP1250StringEncoding, NSISO2022JPStringEncoding, NSMacOSRomanStringEncoding, NSUTF16BigEndianStringEncoding, NSUTF16LittleEndianStringEncoding, NSUTF32StringEncoding, NSUTF32BigEndianStringEncoding, NSUTF32LittleEndianStringEncoding };
    
    int numberOfEncodings = sizeof(encodingsToTest)/sizeof(NSStringEncoding);
    
    NSString *stringToReturn = nil;

    for (int i = 0; i < numberOfEncodings; i++) {
        
        NSStringEncoding currentEndcoding = encodingsToTest[i];
        
        NSString *testString = [NSString stringWithContentsOfFile:self.openFile encoding:currentEndcoding error:nil];

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
    }];
}

- (void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWasShown:(NSNotification *)aNotification {
    BOOL isLandscape = UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication]statusBarOrientation]);
    CGSize kbSize = [aNotification.userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    CGFloat offset = isLandscape?kbSize.width:kbSize.height;
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(_theTextView.contentInset.top, 0, offset, 0);
    
    _theTextView.contentInset = contentInsets;
    _theTextView.scrollIndicatorInsets = contentInsets;
}

- (void)keyboardWillBeHidden:(NSNotification *)aNotification {
    _theTextView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
    _theTextView.scrollIndicatorInsets = _theTextView.contentInset;
}

- (void)textViewDidChange:(UITextView *)textView {
    [self showSaveButton];
    self.hasEdited = YES;
}

- (void)actionSheet:(UIActionSheet *)actionSheet selectedIndex:(NSUInteger)buttonIndex {
    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if ([title isEqualToString:kActionButtonNameEmail]) {
        [kAppDelegate sendFileInEmail:self.openFile];
    } else if ([title isEqualToString:kActionButtonNameP2P]) {
        [[P2PManager shared]sendFileAtPath:self.openFile];
    } else if ([title isEqualToString:kActionButtonNameDBUpload]) {
        [[TaskController sharedController]addTask:[DropboxUpload uploadWithFile:self.openFile]];
    }
}

- (void)showActionSheet:(id)sender {
    [self showActionSheetFromBarButtonItem:(UIBarButtonItem *)sender withButtonTitles:@[kActionButtonNameEmail, kActionButtonNameP2P, kActionButtonNameDBUpload]];
}

- (void)loadText {
    _theTextView.hidden = YES;
    
    UIView *hud = nil;
    
    if (fileSize(self.openFile) > 1024*1024*512) { // if the open file is larger than half a megabyte
        hud = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 100, 100)];
        hud.layer.cornerRadius = 10;
        hud.layer.opacity = 0.7f;
        hud.center = self.view.center;
        hud.backgroundColor = [UIColor darkGrayColor];
        UIActivityIndicatorView *aiv = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        aiv.frame = hud.bounds;
        [aiv startAnimating];
        [hud addSubview:aiv];
        [self.view addSubview:hud];
    }
    
    __weak TextEditorViewController *weakself = self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            NSString *fileContents = [weakself getStringFromFile];
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                @autoreleasepool {
                    [weakself.theTextView setText:fileContents];
                    [weakself.theTextView setHidden:NO];
                    [weakself.view setBackgroundColor:[UIColor whiteColor]];
                    [hud removeFromSuperview];
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
