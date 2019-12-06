//
//  FLEXWebViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 6/10/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#ifdef PGDROID
#else
#import <WebKit/WebKit.h>
#endif
#import "FLEXWebViewController.h"
#import "FLEXUtility.h"

#ifdef PGDROID
@interface FLEXWebViewController () <UIWebViewDelegate>

@property (nonatomic, strong) UIWebView *webView;
#else
@interface FLEXWebViewController () <WKUIDelegate, WKNavigationDelegate>

@property (nonatomic, strong) WKWebView *webView;
#endif
@property (nonatomic, strong) NSString *originalText;

@end

@implementation FLEXWebViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
#ifdef PGDROID
        self.webView = [[UIWebView alloc] init];
        self.webView.delegate = self;
        self.webView.dataDetectorTypes = UIDataDetectorTypeLink;
        self.webView.scalesPageToFit = YES;
#else
        self.webView = [[WKWebView alloc] init];
        self.webView.UIDelegate = self;
        self.webView.navigationDelegate = self;
        self.webView.configuration.dataDetectorTypes = UIDataDetectorTypeLink;
        self.webView.contentMode = UIViewContentModeScaleToFill;
        #if !TARGET_OS_IPHONE
            self.webView.allowsMagnification = YES;
        #endif
#endif
    }
    return self;
}

- (id)initWithText:(NSString *)text
{
    self = [self initWithNibName:nil bundle:nil];
    if (self) {
        self.originalText = text;
        NSString *htmlString = [NSString stringWithFormat:@"<pre>%@</pre>", [FLEXUtility stringByEscapingHTMLEntitiesInString:text]];
        [self.webView loadHTMLString:htmlString baseURL:nil];
    }
    return self;
}

- (id)initWithURL:(NSURL *)url
{
    self = [self initWithNibName:nil bundle:nil];
    if (self) {
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [self.webView loadRequest:request];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view addSubview:self.webView];
    self.webView.frame = self.view.bounds;
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    if ([self.originalText length] > 0) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Copy" style:UIBarButtonItemStylePlain target:self action:@selector(copyButtonTapped:)];
    }
}

- (void)copyButtonTapped:(id)sender
{
    [[UIPasteboard generalPasteboard] setString:self.originalText];
}

#ifdef PGDROID
#pragma mark - UIWebView Delegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    BOOL shouldStart = NO;
    if (navigationType == UIWebViewNavigationTypeOther) {
        // Allow the initial load
        shouldStart = YES;
    } else {
        // For clicked links, push another web view controller onto the navigation stack so that hitting the back button works as expected.
        // Don't allow the current web view do handle the navigation.
        FLEXWebViewController *webVC = [[[self class] alloc] initWithURL:[request URL]];
        [self.navigationController pushViewController:webVC animated:YES];
    }
    return shouldStart;
}
#else
#pragma mark - WKNavigationDelegate Delegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (navigationAction.navigationType == WKNavigationTypeOther) {
        // Allow the initial load
        decisionHandler(WKNavigationActionPolicyAllow);
    } else {
        // For clicked links, push another web view controller onto the navigation stack so that hitting the back button works as expected.
        // Don't allow the current web view do handle the navigation.
        FLEXWebViewController *webVC = [[[self class] alloc] initWithURL:[navigationAction.request URL]];
        [self.navigationController pushViewController:webVC animated:YES];
        decisionHandler(WKNavigationActionPolicyCancel);
    }
}

#pragma mark - WKUIDelegate Delegate
- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}
#endif


#pragma mark - Class Helpers

+ (BOOL)supportsPathExtension:(NSString *)extension
{
    BOOL supported = NO;
    NSSet *supportedExtensions = [self webViewSupportedPathExtensions];
    if ([supportedExtensions containsObject:[extension lowercaseString]]) {
        supported = YES;
    }
    return supported;
}

+ (NSSet *)webViewSupportedPathExtensions
{
    static NSSet *pathExtenstions = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Note that this is not exhaustive, but all these extensions should work well in the web view.
        // See https://developer.apple.com/library/ios/documentation/AppleApplications/Reference/SafariWebContent/CreatingContentforSafarioniPhone/CreatingContentforSafarioniPhone.html#//apple_ref/doc/uid/TP40006482-SW7
        pathExtenstions = [NSSet setWithArray:@[@"jpg", @"jpeg", @"png", @"gif", @"pdf", @"svg", @"tiff", @"3gp", @"3gpp", @"3g2",
                                                @"3gp2", @"aiff", @"aif", @"aifc", @"cdda", @"amr", @"mp3", @"swa", @"mp4", @"mpeg",
                                                @"mpg", @"mp3", @"wav", @"bwf", @"m4a", @"m4b", @"m4p", @"mov", @"qt", @"mqv", @"m4v"]];
        
    });
    return pathExtenstions;
}

@end
