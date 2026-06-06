//
//  FLEXAppKitColor.h
//  FLEX
//
//  A resolved color fact: the unambiguous sRGB hex snapshot PLUS the catalog/
//  dynamic name where one is available (what a native reimplementation actually
//  uses) PLUS the appearance context it was resolved under. Catalog/dynamic
//  NSColors return nil or throw if components are read without first resolving
//  through an appearance + a concrete color space — this type does that.
//
//  SPEC: domain.walker
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@interface FLEXAppKitColor : NSObject

/// Resolve an NSColor (or a CGColorRef) under `appearance`. Returns nil only if
/// the input is nil. `appearance` may be nil (resolves under the current default).
+ (nullable FLEXAppKitColor *)colorFromColor:(nullable id)nsColorOrCGColor
                                 inAppearance:(nullable id)appearance;

/// sRGB hex "#RRGGBBAA"; nil if the color could not be resolved to components.
@property (nonatomic, readonly, copy, nullable) NSString *hex;
/// Catalog/dynamic name (e.g. "controlAccentColor") where the color is a catalog
/// color; nil otherwise.
@property (nonatomic, readonly, copy, nullable) NSString *catalogName;
/// The appearance the color was resolved under (e.g. "NSAppearanceNameDarkAqua").
@property (nonatomic, readonly, copy, nullable) NSString *appearanceName;

@end

NS_ASSUME_NONNULL_END
