//
//  FLEXAppKitColor.m
//  FLEX
//

#import "FLEXAppKitColor.h"

#if TARGET_OS_OSX

#import <AppKit/AppKit.h>

@interface FLEXAppKitColor ()
@property (nonatomic, copy, nullable) NSString *hex;
@property (nonatomic, copy, nullable) NSString *catalogName;
@property (nonatomic, copy, nullable) NSString *appearanceName;
@end

/// sRGB hex of a color already converted to sRGB, or nil. The caller must convert
/// first — reading components on a non-RGB color throws.
static NSString *FLEXHexOfSRGBColor(NSColor *srgb) {
    if (srgb == nil) {
        return nil;
    }
    int r = (int)lround(srgb.redComponent * 255.0);
    int g = (int)lround(srgb.greenComponent * 255.0);
    int b = (int)lround(srgb.blueComponent * 255.0);
    int a = (int)lround(srgb.alphaComponent * 255.0);
    return [NSString stringWithFormat:@"#%02X%02X%02X%02X", r, g, b, a];
}

@implementation FLEXAppKitColor

+ (nullable FLEXAppKitColor *)colorFromColor:(nullable id)input
                                 inAppearance:(nullable id)appearance {
    if (input == nil) {
        return nil;
    }

    // CGColor (e.g. a layer's backgroundColor): already a flat, baked color. It
    // cannot carry a catalog name and is NOT re-resolvable to a different
    // appearance — the dynamic identity was lost when the view baked it into the
    // layer. Capture the baked sRGB hex as-is; catalogName/appearanceName stay nil.
    if (![input isKindOfClass:[NSColor class]]
        && CFGetTypeID((__bridge CFTypeRef)input) == CGColorGetTypeID()) {
        NSColor *flat = [NSColor colorWithCGColor:(__bridge CGColorRef)input];
        NSString *hex = FLEXHexOfSRGBColor([flat colorUsingColorSpace:[NSColorSpace sRGBColorSpace]]);
        if (hex == nil) {
            return nil; // unconvertible (e.g. a pattern color) — no misleading value
        }
        FLEXAppKitColor *result = [FLEXAppKitColor new];
        result.hex = hex;
        return result;
    }

    if (![input isKindOfClass:[NSColor class]]) {
        return nil;
    }
    NSColor *color = input;
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

    // Resolve to sRGB UNDER the appearance — required for a live catalog/dynamic
    // NSColor, which otherwise returns nil or resolves under the wrong appearance.
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

    result.hex = FLEXHexOfSRGBColor(resolved);
    return result;
}

@end

#endif // TARGET_OS_OSX
