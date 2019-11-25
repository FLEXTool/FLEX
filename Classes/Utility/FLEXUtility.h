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
#import "FLEXAlert.h"

#define FLEXFloor(x) (floor(UIScreen.mainScreen.scale * (x)) / UIScreen.mainScreen.scale)

#ifdef __IPHONE_13_0
#define FLEX_AT_LEAST_IOS13_SDK (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_0)
#else
#define FLEX_AT_LEAST_IOS13_SDK NO
#endif

@interface FLEXUtility : NSObject

+ (UIColor *)consistentRandomColorForObject:(id)object;
+ (NSString *)descriptionForView:(UIView *)view includingFrame:(BOOL)includeFrame;
+ (NSString *)stringForCGRect:(CGRect)rect;
+ (UIViewController *)viewControllerForView:(UIView *)view;
+ (UIViewController *)viewControllerForAncestralView:(UIView *)view;
+ (NSString *)detailDescriptionForView:(UIView *)view;
+ (UIImage *)circularImageWithColor:(UIColor *)color radius:(CGFloat)radius;
+ (UIColor *)hierarchyIndentPatternColor;
+ (NSString *)applicationImageName;
+ (NSString *)applicationName;
+ (NSString *)safeDescriptionForObject:(id)object;
+ (NSString *)safeDebugDescriptionForObject:(id)object;
+ (NSString *)addressOfObject:(id)object;
+ (UIFont *)defaultFontOfSize:(CGFloat)size;
+ (UIFont *)defaultTableViewCellLabelFont;
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

/// Actually more like flatmap, but it seems like the objc way to allow returning nil to omit objects.
/// So, return nil from the block to omit objects, and return an object to include it in the new array.
+ (NSArray *)map:(NSArray *)array block:(id(^)(id obj, NSUInteger idx))mapFunc;

+ (NSArray<UIWindow *> *)allWindows;

// Swizzling utilities

+ (SEL)swizzledSelectorForSelector:(SEL)selector;
+ (BOOL)instanceRespondsButDoesNotImplementSelector:(SEL)selector class:(Class)cls;
+ (void)replaceImplementationOfKnownSelector:(SEL)originalSelector onClass:(Class)class withBlock:(id)block swizzledSelector:(SEL)swizzledSelector;
+ (void)replaceImplementationOfSelector:(SEL)selector withSelector:(SEL)swizzledSelector forClass:(Class)cls withMethodDescription:(struct objc_method_description)methodDescription implementationBlock:(id)implementationBlock undefinedBlock:(id)undefinedBlock;

@end
