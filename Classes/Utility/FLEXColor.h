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

@property (readonly, class) UIColor *primaryBackgroundColor;
+ (UIColor *)primaryBackgroundColorWithAlpha:(CGFloat)alpha;

@property (readonly, class) UIColor *secondaryBackgroundColor;
+ (UIColor *)secondaryBackgroundColorWithAlpha:(CGFloat)alpha;

@property (readonly, class) UIColor *tertiaryBackgroundColor;
+ (UIColor *)tertiaryBackgroundColorWithAlpha:(CGFloat)alpha;

@property (readonly, class) UIColor *groupedBackgroundColor;
+ (UIColor *)groupedBackgroundColorWithAlpha:(CGFloat)alpha;

@property (readonly, class) UIColor *secondaryGroupedBackgroundColor;
+ (UIColor *)secondaryGroupedBackgroundColorWithAlpha:(CGFloat)alpha;

// Text colors
@property (readonly, class) UIColor *primaryTextColor;
@property (readonly, class) UIColor *deemphasizedTextColor;

// UI element colors
@property (readonly, class) UIColor *tintColor;
@property (readonly, class) UIColor *scrollViewBackgroundColor;
@property (readonly, class) UIColor *iconColor;
@property (readonly, class) UIColor *borderColor;
@property (readonly, class) UIColor *toolbarItemHighlightedColor;
@property (readonly, class) UIColor *toolbarItemSelectedColor;
@property (readonly, class) UIColor *hairlineColor;
@property (readonly, class) UIColor *destructiveColor;

// Syntax Colours
@property (readonly, class) UIColor *plainTextColor;
@property (readonly, class) UIColor *commentsColor;
@property (readonly, class) UIColor *documentationMarkupColor;
@property (readonly, class) UIColor *documentationMarkupKeywordsColor;
@property (readonly, class) UIColor *marksColor;
@property (readonly, class) UIColor *stringsColor;
@property (readonly, class) UIColor *charactersColor;
@property (readonly, class) UIColor *numbersColor;
@property (readonly, class) UIColor *keywordsColor;
@property (readonly, class) UIColor *preprocessorStatementsColor;
@property (readonly, class) UIColor *URLsColor;
@property (readonly, class) UIColor *attributesColor;
@property (readonly, class) UIColor *typeDeclarationsColor;
@property (readonly, class) UIColor *otherDeclarationsColor;
@property (readonly, class) UIColor *projectClassNamesColor;
@property (readonly, class) UIColor *projectFunctionAndMethodNamesColor;
@property (readonly, class) UIColor *projectConstantsColor;
@property (readonly, class) UIColor *projectTypeNamesColor;
@property (readonly, class) UIColor *projectInstanceVariablesAndGlobalsColor;
@property (readonly, class) UIColor *projectPreprocessorMacrosColor;
@property (readonly, class) UIColor *otherClassNamesColor;
@property (readonly, class) UIColor *otherFunctionAndMethodNamesColor;
@property (readonly, class) UIColor *otherConstantsColor;
@property (readonly, class) UIColor *otherTypeNamesColor;
@property (readonly, class) UIColor *otherInstanceVariablesAndGlobalsColor;
@property (readonly, class) UIColor *otherPreprocessorMacrosColor;
@property (readonly, class) UIColor *headingColor;

@end

NS_ASSUME_NONNULL_END
