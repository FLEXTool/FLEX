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

#pragma mark - Background Colors

+ (UIColor *)primaryBackgroundColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor systemBackgroundColor];
    } else {
        return [UIColor whiteColor];
    }
}

+ (UIColor *)primaryBackgroundColorWithAlpha:(CGFloat)alpha {
    return [[self primaryBackgroundColor] colorWithAlphaComponent:alpha];
}

+ (UIColor *)secondaryBackgroundColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor secondarySystemBackgroundColor];
    } else {
        return [UIColor colorWithHue:2.0/3.0 saturation:0.02 brightness:0.95 alpha:1];
    }
}

+ (UIColor *)secondaryBackgroundColorWithAlpha:(CGFloat)alpha {
    return [[self secondaryBackgroundColor] colorWithAlphaComponent:alpha];
}

+ (UIColor *)tertiaryBackgroundColor {
    if (@available(iOS 13.0, *)) {
        // All the background/fill colors are varying shades
        // of white and black with really low alpha levels.
        // We use this instead to avoid alpha issues.
        return [UIColor systemGray4Color];
    } else {
        return [UIColor lightGrayColor];
    }
}

+ (UIColor *)tertiaryBackgroundColorWithAlpha:(CGFloat)alpha {
    return [[self tertiaryBackgroundColor] colorWithAlphaComponent:alpha];
}

#pragma mark - Text colors

+ (UIColor *)primaryTextColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor labelColor];
    } else {
        return [UIColor blackColor];
    }
}

+ (UIColor *)deemphasizedTextColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor tertiaryLabelColor];
    } else {
        return [UIColor lightGrayColor];
    }
}

#pragma mark - UI Element Colors

+ (UIColor *)scrollViewBackgroundColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor systemGroupedBackgroundColor];
    } else {
        return [UIColor colorWithHue:2.0/3.0 saturation:0.02 brightness:0.95 alpha:1];
    }
}

+ (UIColor *)iconColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor labelColor];
    } else {
        return [UIColor blackColor];
    }
}

+ (UIColor *)borderColor {
    return [self primaryBackgroundColor];
}

+ (UIColor *)toolbarItemHighlightedColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor quaternaryLabelColor];
    } else {
        return [UIColor colorWithHue:2.0/3.0 saturation:0.1 brightness:0.25 alpha:0.6];
    }
}

+ (UIColor *)toolbarItemSelectedColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor secondaryLabelColor];
    } else {
        return [UIColor colorWithHue:2.0/3.0 saturation:0.1 brightness:0.25 alpha:0.68];
    }
}

@end
