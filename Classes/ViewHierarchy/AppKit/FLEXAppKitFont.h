//
//  FLEXAppKitFont.h
//  FLEX
//
//  Decomposed NSFont facts read off a font carrier. Emits the raw CoreText
//  weight trait AND the nearest named weight — never a lossy NSFontManager
//  (1–14) conversion.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FLEXAppKitFont : NSObject

/// Decompose the font carried by `object` (or its `-cell`), or nil if it carries none.
+ (nullable FLEXAppKitFont *)fontForObject:(id)object;

@property (nonatomic, readonly, copy) NSString *familyName;
@property (nonatomic, readonly) double pointSize;
/// Raw CoreText NSFontWeightTrait, in [-1.0, 1.0]. 0.0 when the descriptor omits it.
@property (nonatomic, readonly) double weightTrait;
/// Nearest named weight ("regular", "semibold", …) to `weightTrait`.
@property (nonatomic, readonly, copy) NSString *weightName;
/// PostScript name (e.g. ".SFNS-Regular"), or nil if unavailable.
@property (nonatomic, readonly, copy, nullable) NSString *postScriptName;
/// Symbolic traits present on the font ("bold", "italic", "monoSpace", …).
@property (nonatomic, readonly, copy) NSArray<NSString *> *traits;

@end

NS_ASSUME_NONNULL_END
