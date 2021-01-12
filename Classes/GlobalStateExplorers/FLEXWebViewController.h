//
//  FLEXWebViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 6/10/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import <UIKit/UIKit.h>

#if TARGET_OS_TV

@class KBWebView;

@protocol KBWebViewDelegate <NSObject>

@optional
- (BOOL)webView:(KBWebView *_Nonnull)webView shouldStartLoadWithRequest:(NSURLRequest *_Nonnull)request navigationType:(NSInteger)navigationType;
- (void)webViewDidStartLoad:(KBWebView *_Nonnull)webView;
- (void)webViewDidFinishLoad:(KBWebView *_Nonnull)webView;
- (void)webView:(KBWebView *_Nonnull)webView didFailLoadWithError:(NSError *_Nullable)error;

@end

@protocol KBWebViewDelegate;

@interface KBWebView: UIView
@property (nullable, nonatomic, assign) id <KBWebViewDelegate> delegate;

- (void)loadRequest:(NSURLRequest *_Nonnull)request;
- (void)loadHTMLString:(NSString *_Nonnull)string baseURL:(nullable NSURL *)baseURL;
- (void)loadData:(NSData *_Nonnull)data MIMEType:(NSString *_Nullable)MIMEType textEncodingName:(NSString *_Nonnull)textEncodingName baseURL:(NSURL *_Nonnull)baseURL;

@property (nullable, nonatomic, readonly, strong) NSURLRequest *request;

- (void)reload;
- (void)stopLoading;

- (void)goBack;
- (void)goForward;
@end

@interface FLEXWebViewController : UIViewController <KBWebViewDelegate>

#else

@interface FLEXWebViewController : UIViewController

#endif


- (id)initWithURL:(NSURL *)url;
- (id)initWithText:(NSString *)text;

+ (BOOL)supportsPathExtension:(NSString *)extension;

@end
