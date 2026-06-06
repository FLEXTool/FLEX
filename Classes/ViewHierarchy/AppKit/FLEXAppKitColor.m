//
//  FLEXAppKitColor.m
//  FLEX
//
//  SPEC: domain.walker
//

#import "FLEXAppKitColor.h"

#if TARGET_OS_OSX

#import <AppKit/AppKit.h>

@interface FLEXAppKitColor ()
@property (nonatomic, copy, nullable) NSString *hex;
@property (nonatomic, copy, nullable) NSString *catalogName;
@property (nonatomic, copy, nullable) NSString *appearanceName;
@end

@implementation FLEXAppKitColor

+ (nullable FLEXAppKitColor *)colorFromColor:(nullable id)input
                                 inAppearance:(nullable id)appearance {
    if (input == nil) {
        return nil;
    }

    NSColor *color = nil;
    if ([input isKindOfClass:[NSColor class]]) {
        color = input;
    } else if (CFGetTypeID((__bridge CFTypeRef)input) == CGColorGetTypeID()) {
        color = [NSColor colorWithCGColor:(__bridge CGColorRef)input];
    }
    if (color == nil) {
        return nil;
    }

    FLEXAppKitColor *result = [FLEXAppKitColor new];

    // Catalog/dynamic NAME, only where the color genuinely is a catalog color
    // (reading colorNameComponent on a non-catalog color throws).
    if (@available(macOS 10.14, *)) {
        if (color.type == NSColorTypeCatalog) {
            result.catalogName = color.colorNameComponent;
        }
    }

    NSAppearance *resolveAppearance = [appearance isKindOfClass:[NSAppearance class]] ? appearance : nil;
    result.appearanceName = resolveAppearance.name;

    // Resolve to sRGB components UNDER the appearance — required for catalog/dynamic
    // colors, which otherwise return nil or throw.
    __block NSColor *resolved = nil;
    void (^toSRGB)(void) = ^{
        resolved = [color colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
    };
    if (resolveAppearance != nil) {
        if (@available(macOS 11.0, *)) {
            [resolveAppearance performAsCurrentDrawingAppearance:toSRGB];
        } else {
            toSRGB();
        }
    } else {
        toSRGB();
    }

    if (resolved != nil) {
        int r = (int)lround(resolved.redComponent * 255.0);
        int g = (int)lround(resolved.greenComponent * 255.0);
        int b = (int)lround(resolved.blueComponent * 255.0);
        int a = (int)lround(resolved.alphaComponent * 255.0);
        result.hex = [NSString stringWithFormat:@"#%02X%02X%02X%02X", r, g, b, a];
    }

    return result;
}

@end

#endif // TARGET_OS_OSX
