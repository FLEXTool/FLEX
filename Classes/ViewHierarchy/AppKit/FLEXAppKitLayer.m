//
//  FLEXAppKitLayer.m
//  FLEX
//

#import "FLEXAppKitLayer.h"

#if TARGET_OS_OSX

#import "FLEXAppKitColor.h"
#import <objc/runtime.h>

@interface FLEXAppKitLayer ()
@property (nonatomic, copy) NSString *className;
@property (nonatomic) double cornerRadius;
@property (nonatomic) BOOL masksToBounds;
@property (nonatomic) double opacity;
@property (nonatomic) double borderWidth;
@property (nonatomic, nullable) FLEXAppKitColor *backgroundColor;
@property (nonatomic, nullable) FLEXAppKitColor *borderColor;
@property (nonatomic) double shadowOpacity;
@property (nonatomic) double shadowRadius;
@property (nonatomic) CGSize shadowOffset;
@property (nonatomic, nullable) FLEXAppKitColor *shadowColor;
@property (nonatomic, copy) NSArray<FLEXAppKitLayer *> *sublayers;
@property (nonatomic) NSInteger sublayerCount;
@property (nonatomic) BOOL truncated;
@end

/// CALayer trees are normally shallow, but pathological backing (CATiledLayer
/// pyramids, WebKit compositing, Metal/AVPlayer stacks) can be deep; cap recursion
/// so a walk can never overflow the stack on a hostile tree.
static const NSInteger kFLEXMaxLayerDepth = 64;

@implementation FLEXAppKitLayer

+ (instancetype)layerFromLayer:(CALayer *)layer inAppearance:(nullable id)appearance {
    return [self layerFromLayer:layer inAppearance:appearance depth:0];
}

+ (instancetype)layerFromLayer:(CALayer *)layer
                  inAppearance:(nullable id)appearance
                         depth:(NSInteger)depth {
    FLEXAppKitLayer *result = [FLEXAppKitLayer new];
    result.className = NSStringFromClass(object_getClass(layer));
    result.cornerRadius = layer.cornerRadius;
    result.masksToBounds = layer.masksToBounds;
    result.opacity = layer.opacity;
    result.borderWidth = layer.borderWidth;
    result.backgroundColor = [FLEXAppKitColor colorFromColor:(__bridge id)layer.backgroundColor
                                               inAppearance:appearance];
    result.borderColor = [FLEXAppKitColor colorFromColor:(__bridge id)layer.borderColor
                                           inAppearance:appearance];
    result.shadowOpacity = layer.shadowOpacity;
    result.shadowRadius = layer.shadowRadius;
    result.shadowOffset = layer.shadowOffset;
    result.shadowColor = [FLEXAppKitColor colorFromColor:(__bridge id)layer.shadowColor
                                           inAppearance:appearance];

    NSArray<CALayer *> *sublayers = layer.sublayers;
    result.sublayerCount = (NSInteger)sublayers.count;
    if (sublayers.count > 0 && depth >= kFLEXMaxLayerDepth) {
        result.truncated = YES;
        result.sublayers = @[];
    } else {
        NSMutableArray<FLEXAppKitLayer *> *subs =
            [NSMutableArray arrayWithCapacity:sublayers.count];
        for (CALayer *sub in sublayers) {
            [subs addObject:[self layerFromLayer:sub inAppearance:appearance depth:depth + 1]];
        }
        result.sublayers = subs;
    }
    return result;
}

@end

#endif // TARGET_OS_OSX
