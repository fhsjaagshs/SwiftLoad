//
//  downloaderViewController.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 8/11/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import "downloaderViewController.h"

@implementation downloaderViewController

@synthesize textField;

- (void)loadView {
    [super loadView];
    self.view.backgroundColor = [UIColor clearColor];
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    CustomNavBar *bar = [[CustomNavBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)];
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"SwiftLoad"];
    topItem.leftBarButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"WebDav" style:UIBarButtonItemStyleBordered target:self action:@selector(showWebDAVController)]autorelease];
    topItem.rightBarButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@" Web " style:UIBarButtonItemStyleBordered target:self action:@selector(showWebBrowser)]autorelease];
    [bar pushNavigationItem:topItem animated:NO];
    [self.view addSubview:bar];
    [self.view bringSubviewToFront:bar];
    [bar release];
    [topItem release];
    
    CustomToolbar *bottomBar = [[CustomToolbar alloc]initWithFrame:CGRectMake(0, screenBounds.size.height-44, screenBounds.size.width, 44)];
    bottomBar.items = [NSArray arrayWithObjects:[[[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"ArrowUp"] style:UIBarButtonItemStylePlain target:self action:@selector(showFileBrowsers)]autorelease], [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]autorelease], [[[UIBarButtonItem alloc]initWithTitle:@"Settings" style:UIBarButtonItemStyleBordered target:self action:@selector(showSettings)]autorelease], nil];
    [self.view addSubview:bottomBar];
    [self.view bringSubviewToFront:bottomBar];
    [bottomBar release];
    
    float height = screenBounds.size.height;
    
    BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    
    CustomButton *button = [[CustomButton alloc]initWithFrame:iPad?CGRectMake(312, 463, 144, 52):CGRectMake(112, 0.543*height, 96, 37)];
    [button setTitle:@"Download" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(download) forControlEvents:UIControlEventTouchUpInside];
    
    CustomButton *files = [[CustomButton alloc]initWithFrame:iPad?CGRectMake(334, 583, 101, 52):CGRectMake(124, 0.676*height, 72, 37)];
    [files setTitle:@"Files" forState:UIControlStateNormal];
    [files addTarget:self action:@selector(showFiles) forControlEvents:UIControlEventTouchUpInside];
    
    if (iPad) {
        [button.titleLabel setFont:[UIFont boldSystemFontOfSize:23]];
        [files.titleLabel setFont:[UIFont boldSystemFontOfSize:23]];
    }
    
    UILabel *swiftLoad = [[UILabel alloc]initWithFrame:iPad?CGRectMake(0, 51, 768, 254):CGRectMake(0, 0.117*height, 320, 106)];
    swiftLoad.text = @"SwiftLoad";
    swiftLoad.font = [UIFont boldSystemFontOfSize:iPad?110:60];
    swiftLoad.textColor = [UIColor colorWithRed:0.0f green:1.0f blue:1.0f alpha:1.0f];
    swiftLoad.textAlignment = UITextAlignmentCenter;
    swiftLoad.layer.shadowColor = [UIColor colorWithRed:105.0f/255.0f green:179.0f/255.0f blue:216.0f/255.0f alpha:1.0].CGColor;
    swiftLoad.layer.shadowRadius = 10.0f;
    swiftLoad.layer.shadowOpacity = 1.0f;
    swiftLoad.backgroundColor = [UIColor clearColor];
    
    UIButton *swiftLoadButton = [UIButton buttonWithType:UIButtonTypeCustom];
    swiftLoadButton.frame = swiftLoad.frame;
    [swiftLoadButton addTarget:self action:@selector(showAboutAlert) forControlEvents:UIControlEventTouchUpInside];
    swiftLoadButton.backgroundColor = [UIColor clearColor];
    
    [self.view addSubview:swiftLoadButton];
    [self.view bringSubviewToFront:swiftLoadButton];
    
    [self.view addSubview:swiftLoad];
    [self.view bringSubviewToFront:swiftLoad];
    [swiftLoad release];
    
    [self.view addSubview:button];
    [button release];
    
    [self.view addSubview:files];
    [self.view bringSubviewToFront:files];
    [files release];

    self.textField = [[[UITextField alloc]initWithFrame:iPad?CGRectMake(20, 335, 728, 31):CGRectMake(5, 0.343*height, 310, 31)]autorelease];
    self.textField.borderStyle = UITextBorderStyleRoundedRect;
    self.textField.placeholder = @"Enter URL for download here...";
    [self.textField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self.textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [self.textField setReturnKeyType:UIReturnKeyDone];
    [self.textField setClearButtonMode:UITextFieldViewModeWhileEditing];
    self.textField.adjustsFontSizeToFitWidth = YES;
    self.textField.font = [UIFont systemFontOfSize:12];
    self.textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.textField.textAlignment = UITextAlignmentLeft;
    [self.textField addTarget:self action:@selector(save) forControlEvents:UIControlEventEditingDidEndOnExit];
    [self.view addSubview:self.textField];
    [self.view bringSubviewToFront:self.textField];
    
    [[AVAudioSession sharedInstance]setCategory:AVAudioSessionCategoryPlayback error:nil];
    [self.textField setText:[[NSUserDefaults standardUserDefaults]objectForKey:@"myDefaults"]];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillDisappear) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [DownloadController sharedController];
}

- (void)keyboardWillDisappear {
    [[NSUserDefaults standardUserDefaults]setObject:self.textField.text forKey:@"myDefaults"];
}

- (void)download {
    [self save];
    if (self.textField.text.length > 0) {
        if ([self.textField.text hasPrefix:@"http"]) {
            [kAppDelegate downloadFromAppDelegate:self.textField.text];
        } else if ([self.textField.text hasPrefix:@"ftp"]) {
            [kAppDelegate downloadFileUsingFtp:self.textField.text];
        }
    }
}

- (void)save {
    if ([self.textField isFirstResponder]) {
        [self.textField resignFirstResponder];
    }
    [[NSUserDefaults standardUserDefaults]setObject:self.textField.text forKey:@"myDefaults"];
}

- (void)showFiles {
    [[UIApplication sharedApplication]cancelAllLocalNotifications];
    MyFilesViewController *filesViewMe = [MyFilesViewController viewController];
    filesViewMe.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self presentModalViewController:filesViewMe animated:YES];
}

/*- (void)showWebBrowser {
    webBrowser *wb = [webBrowser viewController];
    wb.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentModalViewController:wb animated:YES];
}*/

- (void)showWebDAVController {
    webDAVViewController *advc = [webDAVViewController viewController];
    advc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentModalViewController:advc animated:YES];
}

- (void)showAboutAlert {
    [self save];
    NSString *version = [[[NSBundle mainBundle]infoDictionary]objectForKey:@"CFBundleShortVersionString"];
    NSString *title = [NSString stringWithFormat:@"SwiftLoad v%@\nBy Nathaniel Symer",version];
    
    CustomAlertView *av = [[CustomAlertView alloc]initWithTitle:title message:@"Maintaining the UNIX spirit since 2011." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [av show];
    [av release];
}

- (void)showSettings {
    SettingsView *d = [SettingsView viewController];
    d.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentModalViewController:d animated:YES];
}

- (void)showFileBrowsers {
    UIActionSheet *actionSheet = [[[UIActionSheet alloc]initWithTitle:nil completionBlock:^(NSUInteger buttonIndex, UIActionSheet *actionSheet) {
        
        if (buttonIndex == 0) {
            FTPBrowserViewController *d = [FTPBrowserViewController viewController];
            d.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            [self presentModalViewController:d animated:YES];
        } else if (buttonIndex == 1) {
            DropboxBrowserViewController *d = [DropboxBrowserViewController viewController];
            d.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            [self presentModalViewController:d animated:YES];
        }
    } cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"FTP Browser", @"Dropbox Browser", nil]autorelease];
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [actionSheet showInView:self.view];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self save];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [self setTextField:nil];
    NSLog(@"%@ dealloc'd", NSStringFromClass([self class]));
    [super dealloc];
}

@end
