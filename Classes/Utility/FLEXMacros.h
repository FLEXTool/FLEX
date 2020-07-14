//
//  FLEXMacros.h
//  FLEX
//
//  Created by Tanner on 3/12/20.
//  Copyright © 2020 Flipboard. All rights reserved.
//

#ifndef FLEXMacros_h
#define FLEXMacros_h

// Used to prevent loading of pre-registered shortcuts and runtime categories in a test environment
#define FLEX_EXIT_IF_TESTING() if (NSClassFromString(@"XCTest")) return;

/// Rounds down to the nearest "point" coordinate
NS_INLINE CGFloat FLEXFloor(CGFloat x) {
    return floor(UIScreen.mainScreen.scale * (x)) / UIScreen.mainScreen.scale;
}

/// Returns the given number of points in pixels
NS_INLINE CGFloat FLEXPointsToPixels(CGFloat points) {
    return points / UIScreen.mainScreen.scale;
}

/// Creates a CGRect with all members rounded down to the nearest "point" coordinate
NS_INLINE CGRect FLEXRectMake(CGFloat x, CGFloat y, CGFloat width, CGFloat height) {
    return CGRectMake(FLEXFloor(x), FLEXFloor(y), FLEXFloor(width), FLEXFloor(height));
}

/// Adjusts the origin of an existing rect
NS_INLINE CGRect FLEXRectSetOrigin(CGRect r, CGPoint origin) {
    r.origin = origin; return r;
}

/// Adjusts the size of an existing rect
NS_INLINE CGRect FLEXRectSetSize(CGRect r, CGSize size) {
    r.size = size; return r;
}

/// Adjusts the origin.x of an existing rect
NS_INLINE CGRect FLEXRectSetX(CGRect r, CGFloat x) {
    r.origin.x = x; return r;
}

/// Adjusts the origin.y of an existing rect
NS_INLINE CGRect FLEXRectSetY(CGRect r, CGFloat y) {
    r.origin.y = y ; return r;
}

/// Adjusts the size.width of an existing rect
NS_INLINE CGRect FLEXRectSetWidth(CGRect r, CGFloat width) {
    r.size.width = width; return r;
}

/// Adjusts the size.height of an existing rect
NS_INLINE CGRect FLEXRectSetHeight(CGRect r, CGFloat height) {
    r.size.height = height; return r;
}

#ifdef __IPHONE_13_0
#define FLEX_AT_LEAST_IOS13_SDK (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_0)
#else
#define FLEX_AT_LEAST_IOS13_SDK NO
#endif

#define FLEXPluralString(count, plural, singular) [NSString \
    stringWithFormat:@"%@ %@", @(count), (count == 1 ? singular : plural) \
]

#define FLEXPluralFormatString(count, pluralFormat, singularFormat) [NSString \
    stringWithFormat:(count == 1 ? singularFormat : pluralFormat), @(count)  \
]

#define flex_dispatch_after(nSeconds, onQueue, block) \
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, \
    (int64_t)(nSeconds * NSEC_PER_SEC)), onQueue, block)

#endif /* FLEXMacros_h */
