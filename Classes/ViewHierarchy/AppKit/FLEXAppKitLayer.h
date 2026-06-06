//
//  FLEXAppKitLayer.h
//  FLEX
//
//  CALayer facts where a view is layer-backed, plus the recursive sublayer tree.
//  This is a structure PARALLEL to the view tree: layer.sublayers != view.subviews,
//  and standalone sublayers (backing no view) are included here. CALayer is the
//  same class on macOS and iOS, so this is cross-platform.
//
//  SPEC: domain.walker
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@class FLEXAppKitColor;

NS_ASSUME_NONNULL_BEGIN

@interface FLEXAppKitLayer : NSObject

+ (instancetype)layerFromLayer:(CALayer *)layer inAppearance:(nullable id)appearance;

@property (nonatomic, readonly, copy) NSString *className;
@property (nonatomic, readonly) double cornerRadius;
@property (nonatomic, readonly) BOOL masksToBounds;
@property (nonatomic, readonly) double opacity;
@property (nonatomic, readonly) double borderWidth;
@property (nonatomic, readonly, nullable) FLEXAppKitColor *backgroundColor;
@property (nonatomic, readonly, nullable) FLEXAppKitColor *borderColor;
@property (nonatomic, readonly) double shadowOpacity;
@property (nonatomic, readonly) double shadowRadius;
@property (nonatomic, readonly) CGSize shadowOffset;
@property (nonatomic, readonly, nullable) FLEXAppKitColor *shadowColor;
/// The parallel sublayer tree, including standalone sublayers backing no view.
@property (nonatomic, readonly, copy) NSArray<FLEXAppKitLayer *> *sublayers;

@end

NS_ASSUME_NONNULL_END
