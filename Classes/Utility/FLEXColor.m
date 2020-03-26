//
//  FLEXColor.m
//  FLEX
//
//  Created by Benny Wong on 6/18/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import "FLEXColor.h"
#import "FLEXUtility.h"

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

+ (UIColor *)toolbarItemHighlightedColor {
    return FLEXDynamicColor(
        quaternaryLabelColor,
        colorWithHue:2.0/3.0 saturation:0.1 brightness:0.25 alpha:0.6
    );
}

+ (UIColor *)toolbarItemSelectedColor {
    return FLEXDynamicColor(
        secondaryLabelColor,
        colorWithHue:2.0/3.0 saturation:0.1 brightness:0.25 alpha:0.68
    );
}

+ (UIColor *)hairlineColor {
    return FLEXDynamicColor(systemGray3Color, colorWithWhite:0.75 alpha:1);
}

+ (UIColor *)destructiveColor {
    return FLEXDynamicColor(systemRedColor, redColor);
}

#pragma mark - Syntax Colours

+ (UIColor *)plainTextColor {
    return FLEXDynamicColor(labelColor, whiteColor);
}

+ (UIColor *)commentsColor {
    return FLEXDynamicColor(colorWithRed:0.42353 green:0.47451 blue:0.52549 alpha:1.00000, colorWithRed:0.36471 green:0.42353 blue:0.47451 alpha:1.00000);
}

+ (UIColor *)documentationMarkupColor {
    return FLEXDynamicColor(colorWithRed:0.42353 green:0.47451 blue:0.52549 alpha:1.00000, colorWithRed:0.36471 green:0.42353 blue:0.47451 alpha:1.00000);
}

+ (UIColor *)documentationMarkupKeywordsColor {
    return FLEXDynamicColor(colorWithRed:0.57255 green:0.63137 blue:0.69412 alpha:1.00000, colorWithRed:0.29020 green:0.33333 blue:0.37647 alpha:1.00000);
}

+ (UIColor *)marksColor {
    return FLEXDynamicColor(colorWithRed:0.57255 green:0.63137 blue:0.69412 alpha:1.00000, colorWithRed:0.29020 green:0.33333 blue:0.37647 alpha:1.00000);
}

+ (UIColor *)stringsColor {
    return FLEXDynamicColor(colorWithRed:0.98824 green:0.41569 blue:0.36471 alpha:1.00000, colorWithRed:0.76863 green:0.10196 blue:0.08627 alpha:1.00000);
}

+ (UIColor *)charactersColor {
    return FLEXDynamicColor(colorWithRed:0.81569 green:0.74902 blue:0.41176 alpha:1.00000, colorWithRed:0.10980 green:0.00000 blue:0.81176 alpha:1.00000);
}

+ (UIColor *)numbersColor {
    return FLEXDynamicColor(colorWithRed:0.81569 green:0.74902 blue:0.41176 alpha:1.00000, colorWithRed:0.10980 green:0.00000 blue:0.81176 alpha:1.00000);
}

+ (UIColor *)keywordsColor {
    return FLEXDynamicColor(colorWithRed:0.98824 green:0.37255 blue:0.63922 alpha:1.00000, colorWithRed:0.60784 green:0.13725 blue:0.57647 alpha:1.00000);
}

+ (UIColor *)preprocessorStatementsColor {
    return FLEXDynamicColor(colorWithRed:0.99216 green:0.56078 blue:0.24706 alpha:1.00000, colorWithRed:0.39216 green:0.21961 blue:0.12549 alpha:1.00000);
}

+ (UIColor *)URLsColor {
    return FLEXDynamicColor(colorWithRed:0.32941 green:0.50980 blue:1.00000 alpha:1.00000, colorWithRed:0.05490 green:0.05490 blue:1.00000 alpha:1.00000);
}

+ (UIColor *)attributesColor {
    return FLEXDynamicColor(colorWithRed:0.74902 green:0.52157 blue:0.33333 alpha:1.00000, colorWithRed:0.42745 green:0.30196 blue:0.02353 alpha:1.00000);
}

+ (UIColor *)typeDeclarationsColor {
    return FLEXDynamicColor(colorWithRed:0.36471 green:0.84706 blue:1.00000 alpha:1.00000, colorWithRed:0.04314 green:0.30980 blue:0.47451 alpha:1.00000);
}

+ (UIColor *)otherDeclarationsColor {
    return FLEXDynamicColor(colorWithRed:0.25490 green:0.63137 blue:0.75294 alpha:1.00000, colorWithRed:0.05882 green:0.40784 blue:0.62745 alpha:1.00000);
}

+ (UIColor *)projectClassNamesColor {
    return FLEXDynamicColor(colorWithRed:0.61961 green:0.94510 blue:0.86667 alpha:1.00000, colorWithRed:0.10980 green:0.27451 blue:0.29020 alpha:1.00000);
}

+ (UIColor *)projectFunctionAndMethodNamesColor {
    return FLEXDynamicColor(colorWithRed:0.40392 green:0.71765 blue:0.64314 alpha:1.00000, colorWithRed:0.19608 green:0.42745 blue:0.45490 alpha:1.00000);
}

+ (UIColor *)projectConstantsColor {
    return FLEXDynamicColor(colorWithRed:0.40392 green:0.71765 blue:0.64314 alpha:1.00000, colorWithRed:0.19608 green:0.42745 blue:0.45490 alpha:1.00000);
}

+ (UIColor *)projectTypeNamesColor {
    return FLEXDynamicColor(colorWithRed:0.61961 green:0.94510 blue:0.86667 alpha:1.00000, colorWithRed:0.10980 green:0.27451 blue:0.29020 alpha:1.00000);
}

+ (UIColor *)projectInstanceVariablesAndGlobalsColor {
    return FLEXDynamicColor(colorWithRed:0.40392 green:0.71765 blue:0.64314 alpha:1.00000, colorWithRed:0.19608 green:0.42745 blue:0.45490 alpha:1.00000);
}

+ (UIColor *)projectPreprocessorMacrosColor {
    return FLEXDynamicColor(colorWithRed:0.99216 green:0.56078 blue:0.24706 alpha:1.00000, colorWithRed:0.39216 green:0.21961 blue:0.12549 alpha:1.00000);
}

+ (UIColor *)otherClassNamesColor {
    return FLEXDynamicColor(colorWithRed:0.81569 green:0.65882 blue:1.00000 alpha:1.00000, colorWithRed:0.22353 green:0.00000 blue:0.62745 alpha:1.00000);
}

+ (UIColor *)otherFunctionAndMethodNamesColor {
    return FLEXDynamicColor(colorWithRed:0.63137 green:0.40392 blue:0.90196 alpha:1.00000, colorWithRed:0.42353 green:0.21176 blue:0.66275 alpha:1.00000);
}

+ (UIColor *)otherConstantsColor {
    return FLEXDynamicColor(colorWithRed:0.63137 green:0.40392 blue:0.90196 alpha:1.00000, colorWithRed:0.42353 green:0.21176 blue:0.66275 alpha:1.00000);
}

+ (UIColor *)otherTypeNamesColor {
    return FLEXDynamicColor(colorWithRed:0.81569 green:0.65882 blue:1.00000 alpha:1.00000, colorWithRed:0.22353 green:0.00000 blue:0.62745 alpha:1.00000);
}

+ (UIColor *)otherInstanceVariablesAndGlobalsColor {
    return FLEXDynamicColor(colorWithRed:0.63137 green:0.40392 blue:0.90196 alpha:1.00000, colorWithRed:0.42353 green:0.21176 blue:0.66275 alpha:1.00000);
}

+ (UIColor *)otherPreprocessorMacrosColor {
    return FLEXDynamicColor(colorWithRed:0.99216 green:0.56078 blue:0.24706 alpha:1.00000, colorWithRed:0.39216 green:0.21961 blue:0.12549 alpha:1.00000);
}

+ (UIColor *)headingColor {
    return FLEXDynamicColor(colorWithRed:0.66667 green:0.05098 blue:0.56863 alpha:1.00000, colorWithRed:0.66667 green:0.05098 blue:0.56863 alpha:1.00000);
}

@end
