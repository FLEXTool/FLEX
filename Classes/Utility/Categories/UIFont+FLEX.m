//
//  UIFont+FLEX.m
//  FLEX
//
//  Created by Tanner Bennett on 12/20/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import "UIFont+FLEX.h"

@implementation UIFont (FLEX)

+ (UIFont *)flex_defaultTableCellFont
{
    static UIFont *defaultTableCellFont = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultTableCellFont = [UIFont systemFontOfSize:12.0];
    });

    return defaultTableCellFont;
}

+ (UIFont *)flex_codeFont {
    return [self fontWithName:@"Menlo-Regular" size:self.systemFontSize];
}

+ (UIFont *)flex_smallCodeFont {
    return [self fontWithName:@"Menlo-Regular" size:self.smallSystemFontSize];
}

@end
