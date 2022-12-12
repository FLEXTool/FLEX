//
//  FLEXUtility.h
//  Flipboard
//
//  Created by Ryan Olson on 4/18/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import <Availability.h>
#import <AvailabilityInternal.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "FLEXTypeEncodingParser.h"
#import "FLEXAlert.h"
#import "NSArray+FLEX.h"
#import "UIFont+FLEX.h"
#import "FLEXMacros.h"

@interface FLEXUtility : NSObject

/// The key window of the app, if it is not a \c FLEXWindow.
/// If it is, then \c FLEXWindow.previousKeyWindow is returned.
@property (nonatomic, readonly, class) UIWindow *appKeyWindow;
/// @return the result of +[UIWindow allWindowsIncludingInternalWindows:onlyVisibleWindows:]
@property (nonatomic, readonly, class) NSArray<UIWindow *> *allWindows;
/// The first active \c UIWindowScene of the app.
@property (nonatomic, readonly, class) UIWindowScene *activeScene API_AVAILABLE(ios(13.0));
/// @return top-most view controller of the given window
+ (UIViewController *)topViewControllerInWindow:(UIWindow *)window;

+ (UIColor *)consistentRandomColorForObject:(id)object;
+ (NSString *)descriptionForView:(UIView *)view includingFrame:(BOOL)includeFrame;
+ (NSString *)stringForCGRect:(CGRect)rect;
+ (UIViewController *)viewControllerForView:(UIView *)view;
+ (UIViewController *)viewControllerForAncestralView:(UIView *)view;
+ (UIImage *)previewImageForView:(UIView *)view;
+ (UIImage *)previewImageForLayer:(CALayer *)layer;
+ (NSString *)detailDescriptionForView:(UIView *)view;
+ (UIImage *)circularImageWithColor:(UIColor *)color radius:(CGFloat)radius;
+ (UIColor *)hierarchyIndentPatternColor;
+ (NSString *)pointerToString:(void *)ptr;
+ (NSString *)addressOfObject:(id)object;
+ (NSString *)stringByEscapingHTMLEntitiesInString:(NSString *)originalString;
+ (UIInterfaceOrientationMask)infoPlistSupportedInterfaceOrientationsMask;
+ (UIImage *)thumbnailedImageWithMaxPixelDimension:(NSInteger)dimension fromImageData:(NSData *)data;
+ (NSString *)stringFromRequestDuration:(NSTimeInterval)duration;
+ (NSString *)statusCodeStringFromURLResponse:(NSURLResponse *)response;
+ (BOOL)isErrorStatusCodeFromURLResponse:(NSURLResponse *)response;
+ (NSArray<NSURLQueryItem *> *)itemsFromQueryString:(NSString *)query;
+ (NSString *)prettyJSONStringFromData:(NSData *)data;
+ (BOOL)isValidJSONData:(NSData *)data;
+ (NSData *)inflatedDataFromCompressedData:(NSData *)compressedData;
+ (BOOL)hasCompressedContentEncoding:(NSURLRequest *)request;

// Swizzling utilities

+ (SEL)swizzledSelectorForSelector:(SEL)selector;
+ (BOOL)instanceRespondsButDoesNotImplementSelector:(SEL)selector class:(Class)cls;
+ (void)replaceImplementationOfKnownSelector:(SEL)originalSelector onClass:(Class)cls withBlock:(id)block swizzledSelector:(SEL)swizzledSelector;
+ (void)replaceImplementationOfSelector:(SEL)selector withSelector:(SEL)swizzledSelector forClass:(Class)cls withMethodDescription:(struct objc_method_description)methodDescription implementationBlock:(id)implementationBlock undefinedBlock:(id)undefinedBlock;

@end
