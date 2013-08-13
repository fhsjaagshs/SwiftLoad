//
//  FileCreationAlertView.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 3/23/13.
//  Copyright (c) 2013 Nathaniel Symer. All rights reserved.
//

#import "FileCreationDialogue.h"
#import <objc/runtime.h>

@implementation FileCreationDialogue

- (id)initWithCompletionBlock:(void (^)(FileCreationDialogueFileType fileType, NSString *fileName))block {
    self = [super initWithTitle:@"Create File or Directory" message:@"\n\n\n" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
    if (self) {
        objc_setAssociatedObject(self, "blockCallback", block, OBJC_ASSOCIATION_COPY_NONATOMIC);
        self.createFile = [[UIButton alloc]init];
        [_createFile setTitle:@"File" forState:UIControlStateNormal];
        [_createFile addTarget:self action:@selector(file) forControlEvents:UIControlEventTouchUpInside];
        [_createFile setTitleColor:[UIColor whiteColor]forState:UIControlStateNormal];
        _createFile.titleLabel.font = [UIFont boldSystemFontOfSize:18];
        [_createFile setTitleShadowColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_createFile setBackgroundColor:[UIColor clearColor]];
        _createFile.titleLabel.shadowOffset = CGSizeMake(0, -1);
        
        self.createDir = [[UIButton alloc]init];
        [_createDir setTitle:@"Directory" forState:UIControlStateNormal];
        [_createDir addTarget:self action:@selector(dir) forControlEvents:UIControlEventTouchUpInside];
        [_createDir setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _createDir.titleLabel.font = [UIFont boldSystemFontOfSize:18];
        [_createDir setTitleShadowColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_createDir setBackgroundColor:[UIColor clearColor]];
        _createDir.titleLabel.shadowOffset = CGSizeMake(0, -1);
        
        self.tv = [[UITextField alloc]init];
        _tv.keyboardAppearance = UIKeyboardAppearanceAlert;
        _tv.borderStyle = UITextBorderStyleLine;
        _tv.backgroundColor = [UIColor whiteColor];
        _tv.returnKeyType = UIReturnKeyDone;
        _tv.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _tv.autocorrectionType = UITextAutocorrectionTypeNo;
        _tv.placeholder = @"file or directory name";
        _tv.textAlignment = UITextAlignmentCenter;
        _tv.font = [UIFont systemFontOfSize:17];
        _tv.adjustsFontSizeToFitWidth = YES;
        _tv.layer.borderWidth = 1.5;
        _tv.layer.borderColor = [UIColor whiteColor].CGColor;
        [_tv addTarget:_tv action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
        
        [self addSubview:_createFile];
        [self addSubview:_createDir];
        [self addSubview:_tv];
        [_tv becomeFirstResponder];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    BOOL landscape = UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication]statusBarOrientation]);
    _tv.frame = CGRectMake(15, landscape?31:45, 255, 27);
    _createFile.frame = CGRectMake(13.5, (self.bounds.size.height/2)-(landscape?10:5), ((self.bounds.size.width-54)/2), 37);
    _createDir.frame = CGRectMake(_createFile.frame.size.width+27, _createFile.frame.origin.y, ((self.bounds.size.width-27)/2), 37);
}

- (void)file {
    [self dismissWithClickedButtonIndex:0 animated:YES];
    [self finishWithName:_tv.text andType:FileCreationDialogueFileTypeFile];
}

- (void)dir {
    [self dismissWithClickedButtonIndex:0 animated:YES];
    [self finishWithName:_tv.text andType:FileCreationDialogueFileTypeDirectory];
}

- (void)finishWithName:(NSString *)name andType:(FileCreationDialogueFileType)type {
    void (^block)(FileCreationDialogueFileType fileType, NSString *fileName) = objc_getAssociatedObject(self, "blockCallback");
	block(type, name);
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self finishWithName:@"cancelled" andType:FileCreationDialogueFileTypeCancel];
    }
}

@end
