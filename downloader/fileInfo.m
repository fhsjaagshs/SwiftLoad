//
//  fileInfo.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 9/13/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import "fileInfo.h"

@implementation fileInfo

@synthesize moddateLabel, fileName, md5Field, revertButton, staticMD5Label;

- (void)loadView {
    [super loadView];
    
    BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    self.view = [[[UIView alloc]initWithFrame:screenBounds]autorelease];
    
    UINavigationBar *navBar = [[[ShadowedNavBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)]autorelease];
    navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"File Details"];
    topItem.leftBarButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)]autorelease];
    [navBar pushNavigationItem:topItem animated:NO];
    [self.view addSubview:navBar];
    [self.view bringSubviewToFront:navBar];
    [topItem release];
    
    UIToolbar *bar = [[[ShadowedToolbar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)]autorelease];
    self.revertButton = [[[UIBarButtonItem alloc]initWithTitle:@"Revert" style:UIBarButtonItemStyleBordered target:self action:@selector(revertAction)]autorelease];
    bar.items = [NSArray arrayWithObjects:[[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]autorelease], nil];
    
    self.fileName = [[[UITextField alloc]initWithFrame:iPad?CGRectMake(20, 163, 728, 31):CGRectMake(8, sanitizeMesurement(92), 305, 31)]autorelease];
    self.fileName.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    self.fileName.borderStyle = UITextBorderStyleRoundedRect;
    self.fileName.placeholder = @"Enter a New Filename...";
    self.fileName.autocorrectionType = UITextAutocorrectionTypeNo;
    self.fileName.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.fileName.returnKeyType = UIReturnKeyDone;
    self.fileName.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.fileName.adjustsFontSizeToFitWidth = YES;
    self.fileName.font = [UIFont systemFontOfSize:14];
    self.fileName.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.fileName.textAlignment = UITextAlignmentCenter;
    self.fileName.delegate = self;
    self.fileName.text = [[kAppDelegate openFile]lastPathComponent];
    self.fileName.inputAccessoryView = bar;
    [self.fileName addTarget:self action:@selector(textFieldDidEndOnExit) forControlEvents:UIControlEventEditingDidEndOnExit];
    [self.fileName addTarget:self action:@selector(textFieldDidChange) forControlEvents:UIControlEventEditingChanged];
    [self.view addSubview:self.fileName];
    [self.view bringSubviewToFront:self.fileName];
    
    BOOL isDir;
    BOOL exists = [[NSFileManager defaultManager]fileExistsAtPath:[kAppDelegate openFile] isDirectory:&isDir];
    
    if (!isDir && exists) {
        self.staticMD5Label = [[[UILabel alloc]initWithFrame:iPad?CGRectMake(0, 163, 768, 31):CGRectMake(0, sanitizeMesurement(219), 320, 21)]autorelease];
        self.staticMD5Label.textColor = myCyan;
        self.staticMD5Label.backgroundColor = [UIColor clearColor];
        self.staticMD5Label.shadowColor = [UIColor darkGrayColor];
        self.staticMD5Label.shadowOffset = CGSizeMake(-1, -1);
        self.staticMD5Label.textAlignment = UITextAlignmentCenter;
        self.staticMD5Label.font = [UIFont boldSystemFontOfSize:iPad?23:17];
        self.staticMD5Label.text = @"MD5 Checksum";
        self.staticMD5Label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [self.view addSubview:self.staticMD5Label];
        
        self.md5Field = [[[UILabel alloc]initWithFrame:iPad?CGRectMake(139, 303, 491, 41):CGRectMake(0, sanitizeMesurement(251), 320, 31)]autorelease];
        self.md5Field.text = @"Loading...";
        self.md5Field.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        self.md5Field.textAlignment = UITextAlignmentCenter;
        self.md5Field.backgroundColor = [UIColor clearColor];
        self.md5Field.font = [UIFont systemFontOfSize:iPad?23:17];
        self.md5Field.textColor = [UIColor whiteColor];
        self.md5Field.shadowColor = [UIColor darkGrayColor];
        self.md5Field.shadowOffset = CGSizeMake(-1, -1);
        [self.view addSubview:self.md5Field];
        
        self.moddateLabel = [[[UILabel alloc]initWithFrame:iPad?CGRectMake(0, 942, 768, 62):CGRectMake(0, sanitizeMesurement(429), 320, 31)]autorelease];
        self.moddateLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        self.moddateLabel.font = [UIFont systemFontOfSize:iPad?26:17];
        self.moddateLabel.textAlignment = UITextAlignmentCenter;
        self.moddateLabel.backgroundColor = [UIColor clearColor];
        self.moddateLabel.shadowColor = [UIColor darkGrayColor];
        self.moddateLabel.shadowOffset = CGSizeMake(-1, -1);
        self.moddateLabel.textColor = [UIColor whiteColor];
        
        NSDate *modDate = [[[NSFileManager defaultManager]attributesOfItemAtPath:[kAppDelegate openFile] error:nil]fileModificationDate];
        NSDateFormatter *formatter = [[[NSDateFormatter alloc]init]autorelease];
        [formatter setTimeStyle:NSDateFormatterNoStyle];
        [formatter setDateStyle:NSDateFormatterMediumStyle];
        [formatter setLocale:[NSLocale currentLocale]];
        [self.moddateLabel setText:[@"Last Modified: " stringByAppendingString:[formatter stringFromDate:modDate]]];
        
        [self.view addSubview:self.moddateLabel];
        [self doMD5];
    }
}

- (void)rename {
    
    NSString *file = [kAppDelegate openFile];
    
    NSString *newName = [[file stringByDeletingLastPathComponent]stringByAppendingPathComponent:self.fileName.text];

    if ([[NSFileManager defaultManager]fileExistsAtPath:newName]) {
        TransparentAlert *av = [[TransparentAlert alloc]initWithTitle:@"Already Exists" message:@"A file already exists with the new name. Please try a different one." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [av show];
        [av release];
        [self.fileName becomeFirstResponder];
    } else {
        if ([[NSFileManager defaultManager]isWritableFileAtPath:file] && [[NSFileManager defaultManager]isReadableFileAtPath:file]) {
            NSMutableDictionary *newNameDict = [NSMutableDictionary dictionary];
            [newNameDict setObject:file forKey:@"old"];
            [newNameDict setObject:newName forKey:@"new"];
            
            [[NSNotificationCenter defaultCenter]postNotificationName:@"copiedlistchanged" object:newNameDict];
            
            [[NSFileManager defaultManager]moveItemAtPath:file toPath:newName error:nil];
            [kAppDelegate setOpenFile:newName];
            
            if ([[kAppDelegate nowPlayingFile] isEqualToString:file]) {
                [kAppDelegate setNowPlayingFile:newName];
            }
        } else {
            NSString *message = [NSString stringWithFormat:@"You do not have the UNIX permissions to rename this file. Try chmod 777 %@ in Terminal on your Mac or Linux machine.", [[kAppDelegate openFile]lastPathComponent]];
            TransparentAlert *av = [[TransparentAlert alloc]initWithTitle:@"Access Denied" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [av show];
            [av release];
            [self.fileName setText:[[kAppDelegate openFile]lastPathComponent]];
        }
    } 
}

- (void)removeRevertButtonFromBar {
    UIToolbar *toolbar = (UIToolbar *)self.fileName.inputAccessoryView;
    
    NSMutableArray *newItems = [NSMutableArray arrayWithArray:toolbar.items];
    
    if (newItems.count == 2) {
        [newItems removeObjectAtIndex:1];
    }
    
    toolbar.items = newItems;
}

- (void)addRevertButtonToBar {
    UIToolbar *toolbar = (UIToolbar *)self.fileName.inputAccessoryView;
    
    NSMutableArray *newItems = [NSMutableArray arrayWithArray:toolbar.items];
    
    if (newItems.count == 1) {
        [newItems insertObject:self.revertButton atIndex:1];
    }
    
    toolbar.items = newItems;
}

- (void)textFieldDidEndOnExit {
    [self.fileName resignFirstResponder];
    
    if (![self.fileName.text isEqualToString:[[kAppDelegate openFile]lastPathComponent]]) {
        [self rename];
    }
    
    [self removeRevertButtonFromBar];
}

- (void)textFieldDidChange {
    if (![self.fileName.text isEqualToString:[[kAppDelegate openFile]lastPathComponent]]) {
        [self addRevertButtonToBar];
    } else {
        [self removeRevertButtonFromBar];
    }
}

- (void)revertAction {
    [self.fileName setText:[[kAppDelegate openFile]lastPathComponent]];
    [self.fileName resignFirstResponder];
    [self removeRevertButtonFromBar];
}

- (void)close {
    [self.fileName resignFirstResponder];
    [self dismissModalViewControllerAnimated:YES];
}

- (void)doMD5 {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
        NSData *fileData = [NSData dataWithContentsOfFile:[kAppDelegate openFile]];
        unsigned char digest[CC_MD5_DIGEST_LENGTH];
        CC_MD5(fileData.bytes, (CC_LONG)fileData.length, digest);
        NSString *md5String = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x", digest[0], digest[1], digest[2], digest[3], digest[4], digest[5], digest[6], digest[7], digest[8], digest[9], digest[10], digest[11], digest[12], digest[13], digest[14], digest[15]];
        
        if (md5String.length > 0) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                NSAutoreleasePool *poolTwo = [[NSAutoreleasePool alloc]init];
                [self.md5Field setText:md5String];
                [poolTwo release];
            });
        }
        
        [pool release];
    });
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (void)dealloc {
    [self setModdateLabel:nil];
    [self setFileName:nil];
    [self setMd5Field:nil];
    [self setRevertButton:nil];
    [self setStaticMD5Label:nil];
    NSLog(@"%@ dealloc'd", NSStringFromClass([self class]));
    [super dealloc];
}

@end
