//
//  FLEXColor.m
//  FLEX
//
//  Created by Benny Wong on 6/18/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import "FLEXColor.h"
#import "FLEXUtility.h"

@implementation FLEXColor

static UIColor *colorWithDynamicProvider(UIColor *lightColor, UIColor *darkColor) {
#if FLEX_AT_LEAST_IOS13_SDK
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            return (traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight
                    ? lightColor
                    : darkColor);
        }];
    }
#endif
    return lightColor;
}

#pragma mark - Background Colors

+ (UIColor *)systemBackgroundColor {
    return [self systemBackgroundColorWithAlpha:1.0];
}

+ (UIColor *)systemBackgroundColorWithAlpha:(CGFloat)alpha {
    return colorWithDynamicProvider([UIColor colorWithWhite:1.0 alpha:alpha],
                                    [UIColor colorWithWhite:0.0 alpha:alpha]);
}

+ (UIColor *)secondaryBackgroundColor {
    return [self secondaryBackgroundColorWithAlpha:1.0];
}

+ (UIColor *)secondaryBackgroundColorWithAlpha:(CGFloat)alpha {
    return colorWithDynamicProvider([UIColor colorWithWhite:0.9 alpha:alpha],
                                    [UIColor colorWithWhite:0.1 alpha:alpha]);
}

#pragma mark - Text colors

+ (UIColor *)primaryTextColor {
    return colorWithDynamicProvider([UIColor blackColor],
                                    [UIColor whiteColor]);
}

+ (UIColor *)deemphasizedTextColor {
    return colorWithDynamicProvider([UIColor lightGrayColor],
                                    [UIColor darkGrayColor]);
}

#pragma mark - UI Element Colors

+ (UIColor *)scrollViewBackgroundColor {
    return colorWithDynamicProvider([UIColor colorWithRed:239.0/255.0 green:239.0/255.0 blue:244.0/255.0 alpha:1.0],
                                    [UIColor colorWithRed:16.0/255.0 green:16.0/255.0 blue:11.0/255.0 alpha:1.0]);
}

+ (UIColor *)iconColor {
    return colorWithDynamicProvider([UIColor darkGrayColor],
                                    [UIColor lightGrayColor]);
}

@end
