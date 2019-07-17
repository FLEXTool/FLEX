//
//  FLEXColor.h
//  FLEX
//
//  Created by Benny Wong on 6/18/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FLEXColor : NSObject

// Background colors, from intense to less intense
+ (UIColor *)primaryBackgroundColor;
+ (UIColor *)primaryBackgroundColorWithAlpha:(CGFloat)alpha;

+ (UIColor *)secondaryBackgroundColor;
+ (UIColor *)secondaryBackgroundColorWithAlpha:(CGFloat)alpha;

+ (UIColor *)tertiaryBackgroundColor;
+ (UIColor *)tertiaryBackgroundColorWithAlpha:(CGFloat)alpha;

// Text colors
+ (UIColor *)primaryTextColor;
+ (UIColor *)deemphasizedTextColor;

// UI element colors
+ (UIColor *)tintColor;
+ (UIColor *)scrollViewBackgroundColor;
+ (UIColor *)iconColor;
+ (UIColor *)borderColor;
+ (UIColor *)toolbarItemHighlightedColor;
+ (UIColor *)toolbarItemSelectedColor;
+ (UIColor *)hairlineColor;

@end

NS_ASSUME_NONNULL_END
