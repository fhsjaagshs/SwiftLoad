//
//  webBrowser.m
//  SwiftLoad
//
//  Created by Nate Symer on 5/8/12.
//  Copyright 2012 Nathaniel Symer. All rights reserved.
//

#import "webBrowser.h"

@implementation webBrowser

@synthesize theTextField, back, forward, theWebView, toolBar, aiv;

- (void)loadView {

    CGRect screenBounds = [[UIScreen mainScreen]applicationFrame];
    
    self.view = [[[UIView alloc]initWithFrame:screenBounds]autorelease];
    
    self.theTextField = [[[CustomTextField alloc]initWithFrame:CGRectMake(69, 7, screenBounds.size.width-75, 31)]autorelease];
    self.theTextField.placeholder = @"Enter a URL...";
    self.theTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.theTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.theTextField.returnKeyType = UIReturnKeyGo;
    self.theTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.theTextField.adjustsFontSizeToFitWidth = YES;
    self.theTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.theTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.theTextField.delegate = self;
    self.theTextField.borderStyle = UITextBorderStyleBezel;
    self.theTextField.backgroundColor = [UIColor clearColor];
    self.theTextField.textAlignment = UITextAlignmentCenter;
    
    UIBarButtonItem *close = [[[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(actionClose)]autorelease];
    UIBarButtonItem *textfield = [[[UIBarButtonItem alloc]initWithCustomView:self.theTextField]autorelease];
    
    CustomToolbar *topBar = [[[CustomToolbar alloc]initWithFrame:CGRectMake(0, 0, screenBounds.size.width, 44)]autorelease];
    topBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    topBar.items = [NSArray arrayWithObjects:close, textfield, nil];
    [self.view addSubview:topBar];
    [self.view bringSubviewToFront:topBar];
    
    self.theWebView = [[[UIWebView alloc]initWithFrame:CGRectMake(0, 44, self.view.bounds.size.width, self.view.bounds.size.height-88)]autorelease];
    self.theWebView.delegate = self;
    self.theWebView.scalesPageToFit = YES;
    self.theWebView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    self.theWebView.backgroundColor = [UIColor clearColor];
    self.theWebView.delegate = self;
    [self.view addSubview:self.theWebView];
    
    self.aiv = [[[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge]autorelease];
    self.aiv.center = CGPointMake(self.view.center.x, self.view.frame.size.height-(self.aiv.frame.size.height/2)-5);
    self.aiv.hidesWhenStopped = YES;
    [self.view addSubview:self.aiv];
    
    self.toolBar = [[[CustomToolbar alloc]initWithFrame:CGRectMake(0, screenBounds.size.height-44, screenBounds.size.width, 44)]autorelease];
    
    self.back = [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemRewind target:self.theWebView action:@selector(goBack)]autorelease];
    self.back.style = UIBarButtonItemStyleBordered;
    self.forward = [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward target:self.theWebView action:@selector(goForward)]autorelease];
    self.forward.style = UIBarButtonItemStyleBordered;
    UIBarButtonItem *space = [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]autorelease];
    UIBarButtonItem *refreshOrCancel = [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(stopOrRefresh)]autorelease];
    
    self.toolBar.items = [NSArray arrayWithObjects:self.back, self.forward, space, refreshOrCancel, nil];
    [self.view addSubview:self.toolBar];
    [self.view bringSubviewToFront:self.toolBar];
    [self updateButtons];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.google.com/"]];
    [self.theWebView loadRequest:request];
}

- (void)stopLoad {
    [self.theWebView stopLoading];
    [self.aiv stopAnimating];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.theTextField setText:[self.theWebView stringByEvaluatingJavaScriptFromString:@"window.location.href"]];
}

- (void)updateButtons {
    self.forward.enabled = self.theWebView.canGoForward;
    self.back.enabled = self.theWebView.canGoBack;
}

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
    BOOL isHTTP = ([request.URL.scheme isEqualToString:@"http"] || [request.URL.scheme isEqualToString:@"https"]);
    BOOL isAudio = [MIMEUtils isAudioFile:request.URL.absoluteString];
    BOOL isImage = [MIMEUtils isImageFile:request.URL.absoluteString];
    BOOL isDocument = [MIMEUtils isDocumentFile:request.URL.absoluteString];
    BOOL isText = [MIMEUtils isTextFile_WebSafe:request.URL.absoluteString];
    BOOL isDownloadable = (isAudio || isImage || isDocument || isText);

    if (isHTTP && isDownloadable) {
        [kAppDelegate downloadFromAppDelegate:request.URL.absoluteString];
        [self.aiv stopAnimating];
        return NO;
    }
    return YES;
}

- (void)actionClose {
    [self dismissModalViewControllerAnimated:YES];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self.theTextField setText:[[self.theWebView stringByEvaluatingJavaScriptFromString:@"window.location.href"]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([[self.theTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:[[self.theWebView stringByEvaluatingJavaScriptFromString:@"window.location.href"]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]]) {
        [self.theTextField setText:[self.theWebView stringByEvaluatingJavaScriptFromString:@"document.title"]];
    }
}

- (void)setRefreshButtonState:(UIBarButtonSystemItem)mode {
    UIBarButtonItem *currentItem = (UIBarButtonItem *)[self.toolBar.items lastObject];
    NSMutableArray *items = [NSMutableArray arrayWithArray:self.toolBar.items];
    int index = [self.toolBar.items indexOfObject:currentItem];
    [items removeObject:currentItem];
    UIBarButtonItem *bbi = [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:mode target:self action:@selector(stopOrRefresh:)]autorelease];
    [bbi setStyle:UIBarButtonItemStyleBordered];
    UIImage *bbiImage = [getButtonImage() resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)];
    [bbi setBackgroundImage:bbiImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [items insertObject:bbi atIndex:index];
    self.toolBar.items = items;
}

- (void)stopOrRefresh {
    if (self.aiv.isAnimating) {
        [self stopLoad];
        [self setRefreshButtonState:UIBarButtonSystemItemRefresh];
    } else {
        [self.theWebView reload];
        [self setRefreshButtonState:UIBarButtonSystemItemStop];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.aiv stopAnimating];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if (!self.theTextField.isFirstResponder) {
        NSString *theTitle = [self.theWebView stringByEvaluatingJavaScriptFromString:@"document.title"];
        [self.theTextField setText:theTitle];
    }
    
    [self updateButtons];
    [self setRefreshButtonState:UIBarButtonSystemItemRefresh];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [self.theTextField setText:@"Loading..."];
    [self.aiv startAnimating];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self updateButtons];
    [self setRefreshButtonState:UIBarButtonSystemItemStop];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if (error.code != -999 && error.code != 102) {
        NSString *title = [NSString stringWithFormat:@"Error %d",error.code];
        NSString *message = [NSString stringWithFormat:@"The webpage failed to load because %@",[[error localizedDescription]lowercaseString]];
        CustomAlertView *av = [[CustomAlertView alloc]initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [av show];
        [av release];
        [self.aiv stopAnimating];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [self updateButtons];
        [self setRefreshButtonState:UIBarButtonSystemItemRefresh];
    }
}

- (void)goAction {
    [self.theWebView stopLoading];
    NSString *text = self.theTextField.text;
    [self.theTextField resignFirstResponder];
    
    if (![text hasPrefix:@"http://"] && (![text hasPrefix:@"https://"] || ![text hasPrefix:@"ftp://"] || ![text hasPrefix:@"afp://"])) {
        text = [@"http://" stringByAppendingString:text];
    }
    
    NSURL *url = [NSURL URLWithString:text];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    [self.theWebView loadRequest:requestObj];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self goAction];
    return YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication]statusBarOrientation])) {
        [self.toolBar setHidden:YES];
        CGRect rectus = CGRectMake(0, 44, self.view.bounds.size.width, self.view.bounds.size.height-44);
        [self.theWebView setFrame:rectus];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    // To Portrait
    if (UIInterfaceOrientationIsLandscape(fromInterfaceOrientation)) {
        [self.toolBar setHidden:NO];
        CGRect rectus = CGRectMake(0, 44, self.view.bounds.size.width, self.view.bounds.size.height-88);
        [self.theWebView setFrame:rectus];
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    // To Landscape
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        [self.toolBar setHidden:YES];
        CGRect rectus = CGRectMake(0, 44, self.view.bounds.size.width, self.view.bounds.size.height-44);
        [self.theWebView setFrame:rectus];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (void)dealloc {
    [self setAiv:nil];
    [self setBack:nil];
    [self setForward:nil];
    [self setTheTextField:nil];
    [self setToolBar:nil];
    [self setTheWebView:nil];
    NSLog(@"%@ dealloc'd", NSStringFromClass([self class]));
    [super dealloc];
}

@end
