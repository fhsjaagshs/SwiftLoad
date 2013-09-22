//
//  fileInfo.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 9/13/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import "FileInfoViewController.h"

static NSString * const kFileInfoCellIdentifier = @"kFileInfoCellIdentifier";

@interface FileInfoViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *theTableView;
@property (nonatomic, strong) NSDateFormatter *formatter;

@property (nonatomic, strong) NSString *md5Sum;

@property (nonatomic, strong) UIAlertView *md5Alert;

@end

@implementation FileInfoViewController

- (void)loadView {
    [super loadView];
    
    self.formatter = [[NSDateFormatter alloc]init];
    [_formatter setTimeStyle:NSDateFormatterNoStyle];
    [_formatter setDateStyle:NSDateFormatterMediumStyle];
    [_formatter setLocale:[NSLocale currentLocale]];
    
    CGRect screenBounds = [[UIScreen mainScreen]bounds];
    
    UINavigationBar *navBar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 64)];
    navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"File Details"];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    [navBar pushNavigationItem:topItem animated:NO];
    [self.view addSubview:navBar];
    
    self.theTableView = [[UITableView alloc]initWithFrame:screenBounds style:UITableViewStyleGrouped];
    _theTableView.delegate = self;
    _theTableView.dataSource = self;
    _theTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    _theTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _theTableView.rowHeight = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)?60:44;
    _theTableView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
    _theTableView.scrollIndicatorInsets = _theTableView.contentInset;
    [self.view addSubview:_theTableView];
    
    [self.view bringSubviewToFront:navBar];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *fileData = [NSData dataWithContentsOfFile:[kAppDelegate openFile]];
        unsigned char digest[CC_MD5_DIGEST_LENGTH];
        CC_MD5(fileData.bytes, (CC_LONG)fileData.length, digest);
        self.md5Sum = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x", digest[0], digest[1], digest[2], digest[3], digest[4], digest[5], digest[6], digest[7], digest[8], digest[9], digest[10], digest[11], digest[12], digest[13], digest[14], digest[15]];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            @autoreleasepool {
                [_theTableView reloadData];
            }
        });
    });
}

- (void)close {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showRenameController {
    UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"Rename File" message:[NSString stringWithFormat:@"Please enter a new name for \"%@\" below",[kAppDelegate openFile].lastPathComponent] completionBlock:^(NSUInteger buttonIndex, UIAlertView *alertView) {
        if (buttonIndex == 1) {
            NSString *file = [kAppDelegate openFile];
            NSString *newFilename = [av textFieldAtIndex:0].text;
            NSString *newFilePath = [[file stringByDeletingLastPathComponent]stringByAppendingPathComponent:newFilename];
            
            if ([[NSFileManager defaultManager]fileExistsAtPath:newFilePath]) {
                NSString *message = [NSString stringWithFormat:@"A file named %@ already exists in %@. Please try a different name.",newFilename,[file stringByDeletingLastPathComponent].lastPathComponent];
                [UIAlertView showAlertWithTitle:@"Filename Unavailable" andMessage:message];
            } else {
                if ([[NSFileManager defaultManager]isWritableFileAtPath:file] && [[NSFileManager defaultManager]isReadableFileAtPath:file]) {
                    [[NSNotificationCenter defaultCenter]postNotificationName:kCopyListChangedNotification object:@{ @"old": file, @"new": newFilePath }];
                    
                    [[NSFileManager defaultManager]moveItemAtPath:file toPath:newFilePath error:nil];
                    [kAppDelegate setOpenFile:newFilePath];
                    
                    if ([[kAppDelegate nowPlayingFile]isEqualToString:file]) {
                        [kAppDelegate setNowPlayingFile:newFilePath];
                    }
                } else {
                    [UIAlertView showAlertWithTitle:@"Access Denied" andMessage:@"You don't have the POSIX permissions to rename this file."];
                }
            }
            [_theTableView reloadData];
        }
    } cancelButtonTitle:@"Cancel" otherButtonTitles:@"Rename", nil];
    
    av.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    UITextField *tv = [av textFieldAtIndex:0];
    tv.returnKeyType = UIReturnKeyDone;
    tv.autocapitalizationType = UITextAutocapitalizationTypeNone;
    tv.autocorrectionType = UITextAutocorrectionTypeNo;
    tv.placeholder = @"Filename";
    tv.clearButtonMode = UITextFieldViewModeWhileEditing;
    tv.text = [kAppDelegate openFile].lastPathComponent;
    
    [av show];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    BOOL isDir;
    return ([[NSFileManager defaultManager]fileExistsAtPath:[kAppDelegate openFile] isDirectory:&isDir] && isDir)?3:4;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == 1 || indexPath.row == 2) {
        return nil;
    }
    
    if (indexPath.row == 3 && _md5Sum.length == 0) {
        return nil;
    }
    
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == 0) {
        [self showRenameController];
    } else if (indexPath.row == 3) {
        [UIAlertView showAlertWithTitle:@"MD5 Sum" andMessage:_md5Sum];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    SwiftLoadCell *cell = (SwiftLoadCell *)[tableView dequeueReusableCellWithIdentifier:kFileInfoCellIdentifier];
    
    if (!cell) {
        cell = [[SwiftLoadCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kFileInfoCellIdentifier];
    }
    
    NSDictionary *attributes = [[NSFileManager defaultManager]attributesOfItemAtPath:[kAppDelegate openFile] error:nil];
    
    cell.textLabel.textColor = [UIColor blackColor];
    
    if (indexPath.row == 0) {
        cell.imageView.image = [UIImage imageNamed:[attributes[NSFileType] isEqualToString:NSFileTypeDirectory]?@"folder_icon":@"file_icon"];
        cell.textLabel.text = [kAppDelegate openFile].lastPathComponent;
    } else if (indexPath.row == 1) {
        cell.textLabel.text = @"Size";
        cell.detailTextLabel.text = [NSString fileSizePrettify:[attributes[NSFileSize] floatValue]];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else if (indexPath.row == 2) {
        cell.textLabel.text = @"Last Modified";
        cell.detailTextLabel.text = [_formatter stringFromDate:attributes[NSFileModificationDate]];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else if (indexPath.row == 3) {
        cell.textLabel.text = @"Checksum";
        cell.textLabel.textColor = _md5Sum.length?[UIColor blackColor]:[UIColor lightGrayColor];
        cell.detailTextLabel.text = nil;
        cell.selectionStyle = _md5Sum.length?UITableViewCellSelectionStyleDefault:UITableViewCellSelectionStyleNone;
    }
    
    return cell;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
