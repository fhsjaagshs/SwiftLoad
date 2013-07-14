//
//  dedicatedTextEditor.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 10/31/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface dedicatedTextEditor : UIViewController <MFMessageComposeViewControllerDelegate, UITextViewDelegate> {
    NSStringEncoding theEncoding;
    BOOL hasEdited;
}

@property (nonatomic, strong) UIActionSheet *popupQuery;
@property (nonatomic, strong) UITextView *theTextView;
@property (nonatomic, strong) UIStepper *stepperFontAdjustment;
@property (nonatomic, strong) UILabel *fontSizeLabel;
@property (nonatomic, strong) ShadowedNavBar *navBar;
@property (nonatomic, strong) ShadowedToolbar *toolBar;

@end
