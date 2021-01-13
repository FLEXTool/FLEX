//
//  FLEXColor.m
//  FLEX
//
//  Created by Benny Wong on 6/18/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXColor.h"
#import "FLEXUtility.h"
#import <UIKit/UIInterface.h>

/**
 
 tvOS notes: alot of these properties are marked as unavailable on tvOS, not only is that a bald faced lie, but without using these values the UI gets completely screwy!
 i initially tried to do some creative macro undef/redef but that didnt work, so going to use good ole KVC, valueForKey: works on class methods as well! and this will work
 perfectly without needing to patch another SDK file for this to build for tvOS
 
 */

#if FLEX_AT_LEAST_IOS13_SDK
#define FLEXDynamicColor(dynamic, static) ({ \
    UIColor *c; \
    if (@available(iOS 13.0, *)) { \
        c = [UIColor dynamic]; \
    } else { \
        c = [UIColor static]; \
    } \
    c; \
});
#else
#define FLEXDynamicColor(dynamic, static) [UIColor static]
#endif

@implementation UIColor (FLEX)

- (UIColor *)inverseColor {
    CGFloat alpha;

    CGFloat red, green, blue;
    if ([self getRed:&red green:&green blue:&blue alpha:&alpha]) {
        return [UIColor colorWithRed:1.0 - red green:1.0 - green blue:1.0 - blue alpha:alpha];
    }

    CGFloat hue, saturation, brightness;
    if ([self getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha]) {
        return [UIColor colorWithHue:1.0 - hue saturation:1.0 - saturation brightness:1.0 - brightness alpha:alpha];
    }

    CGFloat white;
    if ([self getWhite:&white alpha:&alpha]) {
        return [UIColor colorWithWhite:1.0 - white alpha:alpha];
    }

    return nil;
}

@end

@implementation FLEXColor

#pragma mark - Background Colors

+ (UIColor *)primaryBackgroundColor {
    return FLEXDynamicColor(valueForKey:@"systemBackgroundColor", whiteColor);
}

+ (UIColor *)primaryBackgroundColorWithAlpha:(CGFloat)alpha {
    return [[self primaryBackgroundColor] colorWithAlphaComponent:alpha];
}

+ (UIColor *)secondaryBackgroundColor {
    return FLEXDynamicColor(
        valueForKey:@"secondarySystemBackgroundColor",
        colorWithHue:2.0/3.0 saturation:0.02 brightness:0.97 alpha:1
    );
}

+ (UIColor *)secondaryBackgroundColorWithAlpha:(CGFloat)alpha {
    return [[self secondaryBackgroundColor] colorWithAlphaComponent:alpha];
}

+ (UIColor *)tertiaryBackgroundColor {
    // All the background/fill colors are varying shades
    // of white and black with really low alpha levels.
    // We use systemGray4Color instead to avoid alpha issues.
    return FLEXDynamicColor(valueForKey:@"systemGray4Color", lightGrayColor);
}

+ (UIColor *)tertiaryBackgroundColorWithAlpha:(CGFloat)alpha {
    return [[self tertiaryBackgroundColor] colorWithAlphaComponent:alpha];
}

+ (UIColor *)groupedBackgroundColor {
    return FLEXDynamicColor(
        valueForKey:@"systemGroupedBackgroundColor",
        colorWithHue:2.0/3.0 saturation:0.02 brightness:0.97 alpha:1
    );
}

+ (UIColor *)groupedBackgroundColorWithAlpha:(CGFloat)alpha {
    return [[self groupedBackgroundColor] colorWithAlphaComponent:alpha];
}

+ (UIColor *)secondaryGroupedBackgroundColor {
    return FLEXDynamicColor(valueForKey:@"secondarySystemGroupedBackgroundColor", whiteColor);
}

+ (UIColor *)secondaryGroupedBackgroundColorWithAlpha:(CGFloat)alpha {
    return [[self secondaryGroupedBackgroundColor] colorWithAlphaComponent:alpha];
}

#pragma mark - Text colors

+ (UIColor *)primaryTextColor {
    return FLEXDynamicColor(labelColor, blackColor);
}

+ (UIColor *)deemphasizedTextColor {
    return FLEXDynamicColor(valueForKey:@"secondaryLabelColor", lightGrayColor);
}

#pragma mark - UI Element Colors

+ (UIColor *)tintColor {
    #if FLEX_AT_LEAST_IOS13_SDK
    if (@available(iOS 13.0, *)) {
        return [UIColor valueForKey:@"systemBlueColor"];
    } else {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        return UIApplication.sharedApplication.keyWindow.tintColor;
        #pragma clang diagnostic pop
    }
    #else
    return UIApplication.sharedApplication.keyWindow.tintColor;
    #endif
}

+ (UIColor *)scrollViewBackgroundColor {
    return FLEXDynamicColor(
        valueForKey:@"systemGroupedBackgroundColor",
        colorWithHue:2.0/3.0 saturation:0.02 brightness:0.95 alpha:1
    );
}

+ (UIColor *)iconColor {
    return FLEXDynamicColor(labelColor, blackColor);
}

+ (UIColor *)borderColor {
    return [self primaryBackgroundColor];
}

+ (UIColor *)toolbarItemHighlightedColor {
    return FLEXDynamicColor(
        valueForKey:@"quaternaryLabelColor",
        colorWithHue:2.0/3.0 saturation:0.1 brightness:0.25 alpha:0.6
    );
}

+ (UIColor *)toolbarItemSelectedColor {
    return FLEXDynamicColor(
        valueForKey:@"secondaryLabelColor",
        colorWithHue:2.0/3.0 saturation:0.1 brightness:0.25 alpha:0.68
    );
}

+ (UIColor *)hairlineColor {
    return FLEXDynamicColor(valueForKey:@"systemGray3Color", colorWithWhite:0.75 alpha:1);
}

+ (UIColor *)destructiveColor {
    return FLEXDynamicColor(valueForKey:@"systemRedColor", redColor);
}

@end
