//
//  textEditorView.h
//  SwiftLoad
//
//  Created by Nathaniel Symer on 8/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface textEditorView : UIViewController <UITextViewDelegate> {
    IBOutlet UITextView *theTextView;
    IBOutlet UIBarButtonItem *kbButton;
    IBOutlet UIBarButtonItem *closeButton;
}

@end
