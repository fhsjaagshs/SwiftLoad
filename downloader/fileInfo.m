//
//  fileInfo.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 9/13/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import "fileInfo.h"

@interface fileInfo ()

@property (nonatomic, strong) TransparentTextField *fileName;
@property (nonatomic, strong) UILabel *md5Field;
@property (nonatomic, strong) UIBarButtonItem *revertButton;
@property (nonatomic, strong) ShadowedNavBar *navBar;

@end

@implementation fileInfo

- (void)loadView {
    [super loadView];
    
    BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    self.view = [[UIView alloc]initWithFrame:screenBounds];
    
    self.revertButton = [[UIBarButtonItem alloc]initWithTitle:@"Revert" style:UIBarButtonItemStyleBordered target:self action:@selector(revertAction)];
    
    self.navBar = [[ShadowedNavBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)];
    _navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"File Details"];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    [_navBar pushNavigationItem:topItem animated:NO];
    [self.view addSubview:_navBar];
    [self.view bringSubviewToFront:_navBar];
    
    self.fileName = [[TransparentTextField alloc]initWithFrame:iPad?CGRectMake(20, 163, 728, 31):CGRectMake(8, 54, 305, 31)];
    _fileName.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    _fileName.placeholder = @"Enter a New Filename...";
    _fileName.autocorrectionType = UITextAutocorrectionTypeNo;
    _fileName.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _fileName.returnKeyType = UIReturnKeyDone;
    _fileName.clearButtonMode = UITextFieldViewModeWhileEditing;
    _fileName.adjustsFontSizeToFitWidth = YES;
    _fileName.font = [UIFont systemFontOfSize:14];
    _fileName.textAlignment = UITextAlignmentCenter;
    _fileName.text = [[kAppDelegate openFile]lastPathComponent];
    [_fileName addTarget:self action:@selector(textFieldDidEndOnExit) forControlEvents:UIControlEventEditingDidEndOnExit];
    [_fileName addTarget:self action:@selector(textFieldDidChange) forControlEvents:UIControlEventEditingChanged];
    [self.view addSubview:_fileName];
    [self.view bringSubviewToFront:_fileName];
    
    BOOL isDir;
    BOOL exists = [[NSFileManager defaultManager]fileExistsAtPath:[kAppDelegate openFile] isDirectory:&isDir];
    
    if (!isDir && exists) {
        UILabel *staticMD5Label = [[UILabel alloc]initWithFrame:CGRectMake(0, screenBounds.size.height-(iPad?281:231), screenBounds.size.width, iPad?31:21)];
        
        staticMD5Label.textColor = [UIColor blackColor];
        staticMD5Label.backgroundColor = [UIColor clearColor];
        staticMD5Label.textAlignment = UITextAlignmentCenter;
        staticMD5Label.font = [UIFont boldSystemFontOfSize:iPad?23:17];
        staticMD5Label.text = @"MD5 Checksum";
        staticMD5Label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [self.view addSubview:staticMD5Label];
        
        self.md5Field = [[UILabel alloc]initWithFrame:CGRectMake(0, screenBounds.size.height-(iPad?241:201), screenBounds.size.width, iPad?41:31)];
        _md5Field.text = @"Loading...";
        _md5Field.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _md5Field.textAlignment = UITextAlignmentCenter;
        _md5Field.backgroundColor = [UIColor clearColor];
        _md5Field.font = [UIFont systemFontOfSize:iPad?23:17];
        _md5Field.textColor = [UIColor blackColor];
        [self.view addSubview:_md5Field];

        NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
        [formatter setTimeStyle:NSDateFormatterNoStyle];
        [formatter setDateStyle:NSDateFormatterMediumStyle];
        [formatter setLocale:[NSLocale currentLocale]];
        
        UILabel *moddateLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, screenBounds.size.height-(iPad?62:31), screenBounds.size.width, iPad?62:31)];
        moddateLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        moddateLabel.font = [UIFont systemFontOfSize:iPad?26:17];
        moddateLabel.textAlignment = UITextAlignmentCenter;
        moddateLabel.backgroundColor = [UIColor clearColor];
        moddateLabel.textColor = [UIColor blackColor];
        moddateLabel.text = [NSString stringWithFormat:@"Last Modified: %@",[formatter stringFromDate:fileDate([kAppDelegate openFile])]];
        [self.view addSubview:moddateLabel];
        [self doMD5];
    }
}

- (void)rename {
    NSString *file = [kAppDelegate openFile];
    NSString *newFilename = _fileName.text;
    NSString *newFilePath = [[file stringByDeletingLastPathComponent]stringByAppendingPathComponent:newFilename];
    
    if ([[NSFileManager defaultManager]fileExistsAtPath:newFilePath]) {
        NSString *message = [NSString stringWithFormat:@"A file named %@ already exists in %@. Please try a different name.",newFilename,[file stringByDeletingLastPathComponent].lastPathComponent];
        [TransparentAlert showAlertWithTitle:@"Filename Unavailable" andMessage:message];
        [_fileName becomeFirstResponder];
    } else {
        [_fileName resignFirstResponder];
        _navBar.topItem.rightBarButtonItem = nil;
        if ([[NSFileManager defaultManager]isWritableFileAtPath:file] && [[NSFileManager defaultManager]isReadableFileAtPath:file]) {
            
            NSDictionary *copyListChange = @{ @"old": file, @"new": newFilePath };
            
            [[NSNotificationCenter defaultCenter]postNotificationName:kCopyListChangedNotification object:copyListChange];
            
            [[NSFileManager defaultManager]moveItemAtPath:file toPath:newFilePath error:nil];
            [kAppDelegate setOpenFile:newFilePath];
            
            if ([[kAppDelegate nowPlayingFile]isEqualToString:file]) {
                [kAppDelegate setNowPlayingFile:newFilePath];
            }
        } else {
            NSString *message = [NSString stringWithFormat:@"You don't have the POSIX permissions to rename this file. Try chmod 777 %@ in a UNIX shell.", [[kAppDelegate openFile]lastPathComponent]];
            [TransparentAlert showAlertWithTitle:@"Access Denied" andMessage:message];
            [_fileName setText:[[kAppDelegate openFile]lastPathComponent]];
        }
    } 
}

- (void)textFieldDidEndOnExit {
    [_fileName resignFirstResponder];
    
    if (![_fileName.text isEqualToString:[[kAppDelegate openFile]lastPathComponent]]) {
        [self rename];
    }
}

- (void)textFieldDidChange {
    _navBar.topItem.rightBarButtonItem = [_fileName.text isEqualToString:[[kAppDelegate openFile]lastPathComponent]]?nil:_revertButton;
}

- (void)revertAction {
    [_fileName setText:[[kAppDelegate openFile]lastPathComponent]];
    [_fileName resignFirstResponder];
    _navBar.topItem.rightBarButtonItem = nil;
}

- (void)close {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)doMD5 {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            NSData *fileData = [NSData dataWithContentsOfFile:[kAppDelegate openFile]];
            unsigned char digest[CC_MD5_DIGEST_LENGTH];
            CC_MD5(fileData.bytes, (CC_LONG)fileData.length, digest);
            NSString *md5String = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x", digest[0], digest[1], digest[2], digest[3], digest[4], digest[5], digest[6], digest[7], digest[8], digest[9], digest[10], digest[11], digest[12], digest[13], digest[14], digest[15]];
            
            if (md5String.length > 0) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    @autoreleasepool {
                        [_md5Field setText:md5String];
                    }
                });
            }
        }
    });
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
}


@end
