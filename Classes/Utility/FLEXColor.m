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

+ (UIColor *)backgoundColor {
    return [self backgoundColorWithAlpha:1.0];
}

+ (UIColor *)backgoundColorWithAlpha:(CGFloat)alpha {
    return [UIColor colorWithWhite:1.0 alpha:alpha];
}

+ (UIColor *)secondaryBackgroundColorWithAlpha:(CGFloat)alpha {
    return [UIColor colorWithWhite:0.9 alpha:alpha];
}

+ (UIColor *)scrollViewBackgroundColor {
    return [UIColor colorWithRed:239.0/255.0 green:239.0/255.0 blue:244.0/255.0 alpha:1.0];
}

+ (UIColor *)primaryTextColor {
    return [UIColor blackColor];
}

+ (UIColor *)deemphasizedTextColor {
    return [UIColor lightGrayColor];
}

@end
