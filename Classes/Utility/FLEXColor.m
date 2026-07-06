//
//  FLEXColor.m
//  FLEX
//
//  Created by Benny Wong on 6/18/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXColor.h"
#import "FLEXUtility.h"

#define FLEXDynamicColor(dynamic, static) ({ \
    UIColor *c; \
    if (@available(iOS 13.0, *)) { \
        c = [UIColor dynamic]; \
    } else { \
        c = [UIColor static]; \
    } \
    c; \
});

@implementation FLEXColor

#pragma mark - Background Colors

+ (UIColor *)primaryBackgroundColor {
    return FLEXDynamicColor(systemBackgroundColor, whiteColor);
}

+ (UIColor *)primaryBackgroundColorWithAlpha:(CGFloat)alpha {
    return [[self primaryBackgroundColor] colorWithAlphaComponent:alpha];
}

+ (UIColor *)secondaryBackgroundColor {
    return FLEXDynamicColor(
        secondarySystemBackgroundColor,
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
    return FLEXDynamicColor(systemGray4Color, lightGrayColor);
}

+ (UIColor *)tertiaryBackgroundColorWithAlpha:(CGFloat)alpha {
    return [[self tertiaryBackgroundColor] colorWithAlphaComponent:alpha];
}

+ (UIColor *)groupedBackgroundColor {
    return FLEXDynamicColor(
        systemGroupedBackgroundColor,
        colorWithHue:2.0/3.0 saturation:0.02 brightness:0.97 alpha:1
    );
}

+ (UIColor *)groupedBackgroundColorWithAlpha:(CGFloat)alpha {
    return [[self groupedBackgroundColor] colorWithAlphaComponent:alpha];
}

+ (UIColor *)secondaryGroupedBackgroundColor {
    return FLEXDynamicColor(secondarySystemGroupedBackgroundColor, whiteColor);
}

+ (UIColor *)secondaryGroupedBackgroundColorWithAlpha:(CGFloat)alpha {
    return [[self secondaryGroupedBackgroundColor] colorWithAlphaComponent:alpha];
}

#pragma mark - Text colors

+ (UIColor *)primaryTextColor {
    return FLEXDynamicColor(labelColor, blackColor);
}

+ (UIColor *)deemphasizedTextColor {
    return FLEXDynamicColor(secondaryLabelColor, lightGrayColor);
}

#pragma mark - UI Element Colors

+ (UIColor *)tintColor {
    #if FLEX_AT_LEAST_IOS13_SDK
    if (@available(iOS 13.0, *)) {
        return UIColor.systemBlueColor;
    } else {
        return UIApplication.sharedApplication.keyWindow.tintColor;
    }
    #else
    return UIApplication.sharedApplication.keyWindow.tintColor;
    #endif
}

+ (UIColor *)scrollViewBackgroundColor {
    return FLEXDynamicColor(
        systemGroupedBackgroundColor,
        colorWithHue:2.0/3.0 saturation:0.02 brightness:0.95 alpha:1
    );
}

+ (UIColor *)iconColor {
    return FLEXDynamicColor(labelColor, blackColor);
}

+ (UIColor *)borderColor {
    return [self primaryBackgroundColor];
}

+ (UIColor *)toolbarBackgroundColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traits) {
            if (traits.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor colorWithWhite:1.0 alpha:0.82];
            }

            return [UIColor colorWithWhite:0.0 alpha:0.78];
        }];
    }

    return [UIColor colorWithWhite:0.0 alpha:0.78];
}

+ (UIColor *)toolbarDescriptionBackgroundColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traits) {
            if (traits.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor colorWithWhite:1.0 alpha:0.90];
            }

            return [UIColor colorWithWhite:0.0 alpha:0.86];
        }];
    }

    return [UIColor colorWithWhite:0.0 alpha:0.86];
}

+ (UIColor *)toolbarTextColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traits) {
            if (traits.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return UIColor.blackColor;
            }

            return UIColor.whiteColor;
        }];
    }

    return UIColor.whiteColor;
}

+ (UIColor *)toolbarDisabledTextColor {
    return [[self toolbarTextColor] colorWithAlphaComponent:0.45];
}

+ (UIColor *)toolbarDragHandleColor {
    return [[self toolbarTextColor] colorWithAlphaComponent:0.72];
}

+ (UIColor *)toolbarItemHighlightedColor {
    return [[self toolbarTextColor] colorWithAlphaComponent:0.18];
}

+ (UIColor *)toolbarItemSelectedColor {
    return [[self toolbarTextColor] colorWithAlphaComponent:0.28];
}

+ (UIColor *)hairlineColor {
    return FLEXDynamicColor(systemGray3Color, colorWithWhite:0.75 alpha:1);
}

+ (UIColor *)destructiveColor {
    return FLEXDynamicColor(systemRedColor, redColor);
}

@end
