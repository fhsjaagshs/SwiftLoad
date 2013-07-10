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
    self = [super initWithTitle:@"Create File or Directory" message:@"\n\n\n\n" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
    if (self) {
        objc_setAssociatedObject(self, "blockCallback", [block copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        self.createFile = [[[UIButton alloc]initWithFrame:CGRectMake(12, 90, 126, 37)]autorelease];
        [self.createFile setTitle:@"File" forState:UIControlStateNormal];
        [self.createFile addTarget:self action:@selector(file) forControlEvents:UIControlEventTouchUpInside];
        [self.createFile setTitleColor:[UIColor whiteColor]forState:UIControlStateNormal];
        self.createFile.titleLabel.font = [UIFont boldSystemFontOfSize:18];
        [self.createFile setTitleShadowColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.createFile setBackgroundColor:[UIColor clearColor]];
        self.createFile.titleLabel.shadowOffset = CGSizeMake(0, -1);
        
        self.createDir = [[[UIButton alloc]initWithFrame:CGRectMake(145, 90, 126, 37)]autorelease];
        [self.createDir setTitle:@"Directory" forState:UIControlStateNormal];
        [self.createDir addTarget:self action:@selector(dir) forControlEvents:UIControlEventTouchUpInside];
        [self.createDir setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.createDir.titleLabel.font = [UIFont boldSystemFontOfSize:18];
        [self.createDir setTitleShadowColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.createDir setBackgroundColor:[UIColor clearColor]];
        self.createDir.titleLabel.shadowOffset = CGSizeMake(0, -1);
        
        self.tv = [[[UITextField alloc]initWithFrame:CGRectMake(43, 48, 200, 31)]autorelease];
        self.tv.keyboardAppearance = UIKeyboardAppearanceAlert;
        self.tv.borderStyle = UITextBorderStyleBezel;
        self.tv.backgroundColor = [UIColor whiteColor];
        self.tv.returnKeyType = UIReturnKeyDone;
        self.tv.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.tv.autocorrectionType = UITextAutocorrectionTypeNo;
        self.tv.placeholder = @"File/Directory Name";
        self.tv.font = [UIFont boldSystemFontOfSize:18];
        self.tv.adjustsFontSizeToFitWidth = YES;
        [self.tv addTarget:self.tv action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
        
        [self addSubview:self.createFile];
        [self addSubview:self.createDir];
        [self addSubview:self.tv];
        [self.tv becomeFirstResponder];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication]statusBarOrientation])) {
        self.createFile.frame = CGRectMake(13.5, 0.45*self.bounds.size.height-10, ((self.bounds.size.width-27)/2)-13.5, 31);
        self.createDir.frame = CGRectMake(self.createFile.frame.size.width+27, self.createFile.frame.origin.y, ((self.bounds.size.width-27)/2), 31);
        self.tv.frame = CGRectMake(42, self.bounds.size.height/5, self.bounds.size.width-84, 31);
    } else {
        self.createFile.frame = CGRectMake(13.5, 0.45*self.bounds.size.height, ((self.bounds.size.width-27)/2)-13.5, 37);
        self.createDir.frame = CGRectMake(self.createFile.frame.size.width+27, self.createFile.frame.origin.y, ((self.bounds.size.width-27)/2), 37);
        self.tv.frame = CGRectMake(42, self.bounds.size.height/4.5, self.bounds.size.width-84, 31);
    }
    
    for (UIView *view in self.subviews) {
        if ([view isKindOfClass:[UILabel class]]) {
            if ([[(UILabel *)view text]isEqualToString:self.message]) {
                [view setHidden:YES];
            }
        }
        
       /* if ([view isKindOfClass:[UIControl class]] && ![view isKindOfClass:[UITextField class]]) {
            if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication]statusBarOrientation])) {
                view.frame = CGRectMake(view.frame.origin.x+2.5, view.frame.origin.y+10, view.frame.size.width-5, 31);
            } else {
                view.frame = CGRectMake(view.frame.origin.x+2.5, view.frame.origin.y, view.frame.size.width-5, 37);
            }
            
            UIImage *buttonImage = [getUIButtonImageNonPressed(view.frame.size.height) resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)];
            [(UIButton *)view setBackgroundImage:buttonImage forState:UIControlStateNormal];
            
            UIImage *buttonImagePressed = [getUIButtonImagePressed(view.frame.size.height) resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)];
            [(UIButton *)view setBackgroundImage:buttonImagePressed forState:UIControlStateHighlighted];
        }*/
    }
}

- (void)file {
    [self dismissWithClickedButtonIndex:0 animated:YES];
    [self finishWithName:self.tv.text andType:FileCreationDialogueFileTypeFile];
}

- (void)dir {
    [self dismissWithClickedButtonIndex:0 animated:YES];
    [self finishWithName:self.tv.text andType:FileCreationDialogueFileTypeDirectory];
}

- (void)finishWithName:(NSString *)name andType:(FileCreationDialogueFileType)type {
    void (^block)(FileCreationDialogueFileType fileType, NSString *fileName) = objc_getAssociatedObject(self, "blockCallback");
	block(type, name);
    Block_release(block);
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self finishWithName:@"cancelled" andType:FileCreationDialogueFileTypeCancel];
    }
}

@end
