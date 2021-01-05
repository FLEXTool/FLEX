//
//  FLEXWebViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 6/10/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXWebViewController.h"
#import "FLEXUtility.h"
#import <TargetConditionals.h>
#if !TARGET_OS_TV
#import <WebKit/WebKit.h>
@interface FLEXWebViewController () <WKNavigationDelegate>
#else
@interface FLEXWebViewController ()
#endif


#if !TARGET_OS_TV
@property (nonatomic) WKWebView *webView;
#else
@property (nonatomic) KBWebView *webView;
#endif
@property (nonatomic) NSString *originalText;

@end

@implementation FLEXWebViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
#if !TARGET_OS_TV
        WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
        
        if (@available(iOS 10.0, *)) {
            configuration.dataDetectorTypes = UIDataDetectorTypeLink;
        }
        
        self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
        self.webView.navigationDelegate = self;
#else
        self.webView = [[objc_getClass("UIWebView") alloc] initWithFrame:CGRectZero];
        self.webView.delegate = self;
#endif
    }
    return self;
}

- (id)initWithText:(NSString *)text {
    self = [self initWithNibName:nil bundle:nil];
    if (self) {
        self.originalText = text;
        NSString *htmlString = [NSString stringWithFormat:@"<head><meta name='viewport' content='initial-scale=1.0'></head><body><pre>%@</pre></body>", [FLEXUtility stringByEscapingHTMLEntitiesInString:text]];
        [self.webView loadHTMLString:htmlString baseURL:nil];
    }
    return self;
}

- (id)initWithURL:(NSURL *)url {
    self = [self initWithNibName:nil bundle:nil];
    if (self) {
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [self.webView loadRequest:request];
    }
    return self;
}

- (void)dealloc {
    // WKWebView's delegate is assigned so we need to clear it manually.
#if !TARGET_OS_TV
    if (_webView.navigationDelegate == self) {
        _webView.navigationDelegate = nil;
    }
#else
    if (_webView.delegate = self){
        _webView.delegate = nil;
    }
#endif
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.webView];
    self.webView.frame = self.view.bounds;
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    if (self.originalText.length > 0) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Copy" style:UIBarButtonItemStylePlain target:self action:@selector(copyButtonTapped:)];
    }
}

- (void)copyButtonTapped:(id)sender {
#if !TARGET_OS_TV
    [UIPasteboard.generalPasteboard setString:self.originalText];
#endif
}

#if TARGET_OS_TV

#pragma mark - KBWebView Delegate

-(void) webViewDidStartLoad:(KBWebView *)webView {
    LOG_SELF;
}

- (BOOL)webView:(KBWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(NSInteger)navigationType {
    FXLog(@"navtype: %lu", navigationType);
    FXLog(@"urL: %@", request.URL);
    FXLog(@"scheme: %@", request.URL.scheme);
    FXLog(@"navigationType: %lu", navigationType);
    if (navigationType == 5){//
        return YES;
    } else {
        FLEXWebViewController *webVC = [[[self class] alloc] initWithURL:[request URL]];
        webVC.title = [[request URL] absoluteString];
        [self.navigationController pushViewController:webVC animated:YES];
        return NO;//? maybe?
    }
    return YES;
}

-(void) webViewDidFinishLoad:(KBWebView *)webView {
    LOG_SELF;
    
}

#else
#pragma mark - WKWebView Delegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    WKNavigationActionPolicy policy = WKNavigationActionPolicyCancel;
    if (navigationAction.navigationType == WKNavigationTypeOther) {
        // Allow the initial load
        policy = WKNavigationActionPolicyAllow;
    } else {
        // For clicked links, push another web view controller onto the navigation stack so that hitting the back button works as expected.
        // Don't allow the current web view to handle the navigation.
        NSURLRequest *request = navigationAction.request;
        FLEXWebViewController *webVC = [[[self class] alloc] initWithURL:[request URL]];
        webVC.title = [[request URL] absoluteString];
        [self.navigationController pushViewController:webVC animated:YES];
    }
    decisionHandler(policy);
}

#endif

#pragma mark - Class Helpers

+ (BOOL)supportsPathExtension:(NSString *)extension {
    BOOL supported = NO;
    NSSet<NSString *> *supportedExtensions = [self webViewSupportedPathExtensions];
    if ([supportedExtensions containsObject:[extension lowercaseString]]) {
        supported = YES;
    }
    return supported;
}

+ (NSSet<NSString *> *)webViewSupportedPathExtensions {
    static NSSet<NSString *> *pathExtensions = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Note that this is not exhaustive, but all these extensions should work well in the web view.
        // See https://developer.apple.com/library/archive/documentation/AppleApplications/Reference/SafariWebContent/CreatingContentforSafarioniPhone/CreatingContentforSafarioniPhone.html#//apple_ref/doc/uid/TP40006482-SW7
        pathExtensions = [NSSet<NSString *> setWithArray:@[@"jpg", @"jpeg", @"png", @"gif", @"pdf", @"svg", @"tiff", @"3gp", @"3gpp", @"3g2",
                                                           @"3gp2", @"aiff", @"aif", @"aifc", @"cdda", @"amr", @"mp3", @"swa", @"mp4", @"mpeg",
                                                           @"mpg", @"mp3", @"wav", @"bwf", @"m4a", @"m4b", @"m4p", @"mov", @"qt", @"mqv", @"m4v"]];
        
    });
    return pathExtensions;
}

@end
