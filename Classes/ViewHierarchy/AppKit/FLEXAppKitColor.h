//
//  FLEXAppKitColor.h
//  FLEX
//
//  A resolved color fact: the unambiguous sRGB hex snapshot, plus — for live
//  NSColor inputs — the catalog/dynamic name where available (what a native
//  reimplementation actually uses) and the appearance context it was resolved
//  under. A live catalog/dynamic NSColor is resolved through an appearance + a
//  concrete color space (otherwise reading components throws or yields the wrong
//  appearance).
//
//  CGColor inputs (e.g. a CALayer's backgroundColor) are already FLATTENED by the
//  time the walker sees them: the dynamic/catalog identity was baked away when the
//  view set the layer color, so for a CGColor only `hex` is populated (the baked
//  sRGB value); `catalogName` and `appearanceName` are nil and `inAppearance:` is
//  a no-op. Read view-level colors as NSColor (not via the layer) to recover the
//  catalog name and appearance.
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
