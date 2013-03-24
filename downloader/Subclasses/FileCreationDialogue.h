//
//  FileCreationAlertView.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 3/23/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    FileCreationDialogueFileTypeFile,
    FileCreationDialogueFileTypeDirectory,
    FileCreationDialogueFileTypeCancel
} FileCreationDialogueFileType;

@interface FileCreationDialogue : CustomAlertView

- (id)initWithCompletionBlock:(void (^)(FileCreationDialogueFileType fileType, NSString *fileName))block;

@property (nonatomic, retain) CustomTextField *tv;
@property (nonatomic, retain) CustomButton *createFile;
@property (nonatomic, retain) CustomButton *createDir;

@end
