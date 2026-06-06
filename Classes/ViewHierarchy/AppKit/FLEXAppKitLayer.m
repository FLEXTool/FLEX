//
//  FLEXAppKitLayer.m
//  FLEX
//
//  SPEC: domain.walker
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
@end

@implementation FLEXAppKitLayer

+ (instancetype)layerFromLayer:(CALayer *)layer inAppearance:(nullable id)appearance {
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

    NSMutableArray<FLEXAppKitLayer *> *subs =
        [NSMutableArray arrayWithCapacity:layer.sublayers.count];
    for (CALayer *sub in layer.sublayers) {
        [subs addObject:[self layerFromLayer:sub inAppearance:appearance]];
    }
    result.sublayers = subs;
    return result;
}

@end

#endif // TARGET_OS_OSX
