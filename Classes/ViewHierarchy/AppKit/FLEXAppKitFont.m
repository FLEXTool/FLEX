//
//  FLEXAppKitFont.m
//  FLEX
//

#import "FLEXAppKitFont.h"

#if TARGET_OS_OSX

#import <AppKit/AppKit.h>

@interface FLEXAppKitFont ()
@property (nonatomic, copy) NSString *familyName;
@property (nonatomic) double pointSize;
@property (nonatomic) double weightTrait;
@property (nonatomic, copy) NSString *weightName;
@property (nonatomic, copy, nullable) NSString *postScriptName;
@property (nonatomic, copy) NSArray<NSString *> *traits;
@end

/// The font, read off `object` directly or off its `-cell`, or nil. The carrier set is
/// "any object responding to -font" — not a hardcoded class list.
static NSFont *FLEXFontFromCarrier(id object) {
    if (object == nil) {
        return nil;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ([object respondsToSelector:@selector(font)]) {
        id font = [object performSelector:@selector(font)];
        if ([font isKindOfClass:[NSFont class]]) {
            return font;
        }
    }
    if ([object respondsToSelector:@selector(cell)]) {
        id cell = [object performSelector:@selector(cell)];
        if ([cell respondsToSelector:@selector(font)]) {
            id font = [cell performSelector:@selector(font)];
            if ([font isKindOfClass:[NSFont class]]) {
                return font;
            }
        }
    }
#pragma clang diagnostic pop

    return nil;
}

/// Nearest named weight to a raw CoreText trait, using AppKit's own constants so the
/// thresholds track the platform rather than hardcoded folklore numbers.
static NSString *FLEXNearestWeightName(CGFloat weight) {
    const struct { CGFloat value; NSString *name; } weights[] = {
        { NSFontWeightUltraLight, @"ultraLight" },
        { NSFontWeightThin,       @"thin" },
        { NSFontWeightLight,      @"light" },
        { NSFontWeightRegular,    @"regular" },
        { NSFontWeightMedium,     @"medium" },
        { NSFontWeightSemibold,   @"semibold" },
        { NSFontWeightBold,       @"bold" },
        { NSFontWeightHeavy,      @"heavy" },
        { NSFontWeightBlack,      @"black" },
    };

    NSString *nearest = @"regular";
    CGFloat bestDelta = CGFLOAT_MAX;
    for (size_t i = 0; i < sizeof(weights) / sizeof(weights[0]); i++) {
        CGFloat delta = ABS(weight - weights[i].value);
        if (delta < bestDelta) {
            bestDelta = delta;
            nearest = weights[i].name;
        }
    }
    return nearest;
}

static NSArray<NSString *> *FLEXSymbolicTraitNames(NSFontDescriptorSymbolicTraits traits) {
    NSMutableArray<NSString *> *names = [NSMutableArray array];
    if (traits & NSFontDescriptorTraitBold)      { [names addObject:@"bold"]; }
    if (traits & NSFontDescriptorTraitItalic)    { [names addObject:@"italic"]; }
    if (traits & NSFontDescriptorTraitExpanded)  { [names addObject:@"expanded"]; }
    if (traits & NSFontDescriptorTraitCondensed) { [names addObject:@"condensed"]; }
    if (traits & NSFontDescriptorTraitMonoSpace) { [names addObject:@"monoSpace"]; }
    if (traits & NSFontDescriptorTraitVertical)  { [names addObject:@"vertical"]; }
    if (traits & NSFontDescriptorTraitUIOptimized) { [names addObject:@"uiOptimized"]; }
    return names;
}

@implementation FLEXAppKitFont

+ (nullable FLEXAppKitFont *)fontForObject:(id)object {
    NSFont *font = FLEXFontFromCarrier(object);
    if (font == nil) {
        return nil;
    }

    NSDictionary *traitsDict = [font.fontDescriptor objectForKey:NSFontTraitsAttribute];
    NSNumber *weightNumber = traitsDict[NSFontWeightTrait];
    CGFloat weight = weightNumber != nil ? weightNumber.doubleValue : 0.0;

    FLEXAppKitFont *result = [FLEXAppKitFont new];
    result.familyName = font.familyName ?: font.fontName;
    result.pointSize = font.pointSize;
    result.weightTrait = weight;
    result.weightName = FLEXNearestWeightName(weight);
    result.postScriptName = font.fontName;
    result.traits = FLEXSymbolicTraitNames(font.fontDescriptor.symbolicTraits);
    return result;
}

@end

#endif // TARGET_OS_OSX
