//
//  FLEXUtility.h
//  Flipboard
//
//  Created by Ryan Olson on 4/18/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import <Availability.h>
#import <AvailabilityInternal.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "FLEXTypeEncodingParser.h"
#import "FLEXAlert.h"
#import "NSArray+Functional.h"
#import "UIFont+FLEX.h"
#import "NSMapTable+FLEX_Subscripting.h"

/// Rounds down to the nearest "point" coordinate
NS_INLINE CGFloat FLEXFloor(CGFloat x) {
    return floor(UIScreen.mainScreen.scale * (x)) / UIScreen.mainScreen.scale;
}

/// Creates a CGRect with all members rounded down to the nearest "point" coordinate
NS_INLINE CGRect FLEXRectMake(CGFloat x, CGFloat y, CGFloat width, CGFloat height) {
    return CGRectMake(FLEXFloor(x), FLEXFloor(y), FLEXFloor(width), FLEXFloor(height));
}

/// Adjusts the origin of an existing rect
NS_INLINE CGRect FLEXRectSetOrigin(CGRect r, CGPoint origin) {
    r.origin = origin; return r;
}

/// Adjusts the size of an existing rect
NS_INLINE CGRect FLEXRectSetSize(CGRect r, CGSize size) {
    r.size = size; return r;
}

/// Adjusts the origin.x of an existing rect
NS_INLINE CGRect FLEXRectSetX(CGRect r, CGFloat x) {
    r.origin.x = x; return r;
}

/// Adjusts the origin.y of an existing rect
NS_INLINE CGRect FLEXRectSetY(CGRect r, CGFloat y) {
    r.origin.y = y ; return r;
}

/// Adjusts the size.width of an existing rect
NS_INLINE CGRect FLEXRectSetWidth(CGRect r, CGFloat width) {
    r.size.width = width; return r;
}

/// Adjusts the size.height of an existing rect
NS_INLINE CGRect FLEXRectSetHeight(CGRect r, CGFloat height) {
    r.size.height = height; return r;
}

#ifdef __IPHONE_13_0
#define FLEX_AT_LEAST_IOS13_SDK (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_0)
#else
#define FLEX_AT_LEAST_IOS13_SDK NO
#endif

#define FLEXPluralString(count, plural, singular) [NSString \
    stringWithFormat:@"%@ %@", @(count), (count == 1 ? singular : plural) \
]

#define FLEXPluralFormatString(count, pluralFormat, singularFormat) [NSString \
    stringWithFormat:(count == 1 ? singularFormat : pluralFormat), @(count)  \
]

#if !FLEX_AT_LEAST_IOS13_SDK
@class UIWindowScene;
#endif

@interface FLEXUtility : NSObject

/// The key window of the app, if it is not a \c FLEXWindow.
/// If it is, then \c FLEXWindow.previousKeyWindow is returned.
@property (nonatomic, readonly, class) UIWindow *appKeyWindow;
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

+ (NSArray<UIWindow *> *)allWindows;

// Swizzling utilities

+ (SEL)swizzledSelectorForSelector:(SEL)selector;
+ (BOOL)instanceRespondsButDoesNotImplementSelector:(SEL)selector class:(Class)cls;
+ (void)replaceImplementationOfKnownSelector:(SEL)originalSelector onClass:(Class)class withBlock:(id)block swizzledSelector:(SEL)swizzledSelector;
+ (void)replaceImplementationOfSelector:(SEL)selector withSelector:(SEL)swizzledSelector forClass:(Class)cls withMethodDescription:(struct objc_method_description)methodDescription implementationBlock:(id)implementationBlock undefinedBlock:(id)undefinedBlock;

@end
