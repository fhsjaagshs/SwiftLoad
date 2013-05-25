//
//  textEditorView.m
//  SwiftLoad
//
//  Created by Nathaniel Symer on 8/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "textEditorView.h"

@implementation textEditorView

- (IBAction)dismissKeyboard {
    if ([theTextView isFirstResponder]) {
        [theTextView resignFirstResponder];
    }
}

- (IBAction)dismissView {
    if ([theTextView isFirstResponder]) {
        [theTextView resignFirstResponder];
    }
    
    if (closeButton.style == UIBarButtonItemStyleBordered) {
        NSString *theText = [theTextView text];
        NSString *whereToSave = [[NSUserDefaults standardUserDefaults]objectForKey:@"cellNameFileKey"];
        [theText writeToFile:whereToSave atomically:YES encoding:NSUTF8StringEncoding error:nil];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            [theTextView setFrame:CGRectMake(0, 44, 768, 960)];
        } else {
            [theTextView setFrame:CGRectMake(0, 44, 320, 417)];
        }
        [kbButton setEnabled:NO];
        [closeButton setStyle:UIBarButtonItemStyleDone];
        [closeButton setTitle:@"Close"];
    } else if (closeButton.style == UIBarButtonItemStyleDone) {
        [self dismissModalViewControllerAnimated:YES];
    }
    [self dismissModalViewControllerAnimated:YES];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [theTextView setFrame:CGRectMake(0, 44, 768, 960)];
    } else {
        [theTextView setFrame:CGRectMake(0, 44, 320, 417)];
    }
    [kbButton setEnabled:NO];
}

- (void)textViewDidChange:(UITextView *)textView {
    [closeButton setStyle:UIBarButtonItemStyleBordered];
    [closeButton setTitle:@"Save"];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [theTextView setFrame:CGRectMake(0, 44, 768, 696)];
    } else {
        [theTextView setFrame:CGRectMake(0, 44, 320, 200)];
    }
    [kbButton setEnabled:YES];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self = [super initWithNibName:@"textEditorView~iPad" bundle:nibBundleOrNil];
    } else {
        self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - View lifecycle

- (void)saveTheText {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
    NSString *theText = [theTextView text];
    NSString *whereToSave = [[NSUserDefaults standardUserDefaults]objectForKey:@"cellNameFileKey"];
    [theText writeToFile:whereToSave atomically:YES encoding:NSUTF8StringEncoding error:nil];
    [pool release];
}

- (void)viewDidLoad
{ 
    [closeButton release];
    [theTextView release];
    [kbButton release];
    [theTextView setDelegate:self];
    NSString *file = [[NSUserDefaults standardUserDefaults]objectForKey:@"cellNameFileKey"];
    NSStringEncoding encoding = NSUTF8StringEncoding;
    [NSString stringWithContentsOfFile:file usedEncoding:&encoding error:nil];
    NSString *fileContents = [NSString stringWithContentsOfFile:file encoding:encoding error:nil];
    [theTextView setText:fileContents];
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)dealloc
{
    [super dealloc];
}

@end
