//
//  dedicatedTextEditor.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 10/31/11.
//  Copyright 2011 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface dedicatedTextEditor : UIViewController <MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, UITextViewDelegate> {
    NSStringEncoding theEncoding;
    BOOL hasEdited;
}

@property (nonatomic, retain) UIActionSheet *popupQuery;
@property (nonatomic, retain) UITextView *theTextView;
@property (nonatomic, retain) UIStepper *stepperFontAdjustment;
@property (nonatomic, retain) UILabel *fontSizeLabel;
@property (nonatomic, retain) UINavigationBar *navBar;
@property (nonatomic, retain) CustomToolbar *toolBar;

@end
