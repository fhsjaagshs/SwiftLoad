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
    
    self.theTableView = [[UITableView alloc]initWithFrame:screenBounds style:UITableViewStyleGrouped];
    _theTableView.delegate = self;
    _theTableView.dataSource = self;
    _theTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    _theTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _theTableView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
    _theTableView.scrollIndicatorInsets = _theTableView.contentInset;
    [self.view addSubview:_theTableView];
    
    UINavigationBar *navBar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 64)];
    navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *topItem = [[UINavigationItem alloc]initWithTitle:@"File Details"];
    topItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    [navBar pushNavigationItem:topItem animated:NO];
    [self.view addSubview:navBar];
    
    __weak FileInfoViewController *weakself = self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *fileData = [NSData dataWithContentsOfFile:self.openFile];
        unsigned char digest[CC_MD5_DIGEST_LENGTH];
        CC_MD5(fileData.bytes, (CC_LONG)fileData.length, digest);
        weakself.md5Sum = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x", digest[0], digest[1], digest[2], digest[3], digest[4], digest[5], digest[6], digest[7], digest[8], digest[9], digest[10], digest[11], digest[12], digest[13], digest[14], digest[15]];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            @autoreleasepool {
                [weakself.theTableView reloadData];
            }
        });
    });
}

- (void)close {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showRenameController {
    UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"Rename File" message:[NSString stringWithFormat:@"Please enter a new name for \"%@\" below",self.openFile.lastPathComponent] completionBlock:^(NSUInteger buttonIndex, UIAlertView *alertView) {
        if (buttonIndex == 1) {
            NSString *newFilename = [alertView textFieldAtIndex:0].text;
            NSString *newFilePath = [[self.openFile stringByDeletingLastPathComponent]stringByAppendingPathComponent:newFilename];
            
            if ([[NSFileManager defaultManager]fileExistsAtPath:newFilePath]) {
                NSString *message = [NSString stringWithFormat:@"A file named %@ already exists in %@. Please try a different name.",newFilename,[self.openFile stringByDeletingLastPathComponent].lastPathComponent];
                [UIAlertView showAlertWithTitle:@"Filename Unavailable" andMessage:message];
            } else {
                if ([[NSFileManager defaultManager]isWritableFileAtPath:self.openFile] && [[NSFileManager defaultManager]isReadableFileAtPath:self.openFile]) {
                    [[NSNotificationCenter defaultCenter]postNotificationName:kCopyListChangedNotification object:@{ @"old": self.openFile, @"new": newFilePath }];
                    
                    [[NSFileManager defaultManager]moveItemAtPath:self.openFile toPath:newFilePath error:nil];
                    
                    if ([kAppDelegate.nowPlayingFile isEqualToString:self.openFile]) {
                        [kAppDelegate setNowPlayingFile:newFilePath];
                    }
                    
                    self.openFile = newFilePath;
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
    tv.text = self.openFile.lastPathComponent;
    
    [av show];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return isDirectory(self.openFile)?2:4;
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
        cell.textLabel.textColor = [UIColor blackColor];
    }
    
    NSDictionary *attributes = [[NSFileManager defaultManager]attributesOfItemAtPath:self.openFile error:nil];

    if (isDirectory(self.openFile)) {
        if (indexPath.row == 0) {
            cell.imageView.image = [UIImage imageNamed:@"folder_icon"];
            cell.textLabel.text = self.openFile.lastPathComponent;
        } else if (indexPath.row == 1) {
            cell.textLabel.text = @"Created";
            cell.detailTextLabel.text = [_formatter stringFromDate:attributes[NSFileCreationDate]];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
    } else {
        if (indexPath.row == 0) {
            cell.imageView.image = [UIImage imageNamed:@"file_icon"];
            cell.textLabel.text = self.openFile.lastPathComponent;
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
