//
//  FLEXAppKitJSON.m
//  FLEX
//

#import "FLEXAppKitJSON.h"

#if TARGET_OS_OSX

#import "FLEXAppKitViewSnapshot.h"
#import "FLEXAppKitWindowSnapshot.h"
#import "FLEXAppKitFont.h"
#import "FLEXAppKitLayer.h"
#import "FLEXAppKitColor.h"
#import "FLEXConstraintNode.h"

static id orNull(id _Nullable value) {
    return value ?: [NSNull null];
}

/// Fixed precision (1 dp) for diffable, deterministic output.
static NSNumber *num1(double value) {
    return @(round(value * 10.0) / 10.0);
}

static NSDictionary *rectDict(CGRect r) {
    return @{ @"x": num1(r.origin.x), @"y": num1(r.origin.y),
              @"w": num1(r.size.width), @"h": num1(r.size.height) };
}

@implementation FLEXAppKitJSON

+ (id)colorDict:(FLEXAppKitColor *)color {
    if (color == nil) {
        return [NSNull null];
    }
    return @{ @"hex": orNull(color.hex),
              @"catalogName": orNull(color.catalogName),
              @"appearanceName": orNull(color.appearanceName) };
}

+ (id)fontDict:(FLEXAppKitFont *)font {
    if (font == nil) {
        return [NSNull null];
    }
    return @{ @"family": orNull(font.familyName),
              @"size": num1(font.pointSize),
              @"weightTrait": @(font.weightTrait),
              @"weightName": orNull(font.weightName),
              @"postScriptName": orNull(font.postScriptName),
              @"traits": font.traits ?: @[] };
}

+ (id)layerDict:(FLEXAppKitLayer *)layer {
    if (layer == nil) {
        return [NSNull null];
    }
    NSMutableArray *sublayers = [NSMutableArray array];
    for (FLEXAppKitLayer *sub in layer.sublayers) {
        [sublayers addObject:[self layerDict:sub]];
    }
    return @{ @"class": orNull(layer.className),
              @"cornerRadius": num1(layer.cornerRadius),
              @"masksToBounds": @(layer.masksToBounds),
              @"opacity": num1(layer.opacity),
              @"borderWidth": num1(layer.borderWidth),
              @"backgroundColor": [self colorDict:layer.backgroundColor],
              @"borderColor": [self colorDict:layer.borderColor],
              @"shadowOpacity": num1(layer.shadowOpacity),
              @"shadowRadius": num1(layer.shadowRadius),
              @"shadowOffset": @{ @"w": num1(layer.shadowOffset.width), @"h": num1(layer.shadowOffset.height) },
              @"shadowColor": [self colorDict:layer.shadowColor],
              @"sublayerCount": @(layer.sublayerCount),
              @"truncated": @(layer.truncated),
              @"sublayers": sublayers };
}

+ (NSDictionary *)dictionaryForView:(FLEXAppKitViewSnapshot *)view {
    NSMutableArray *children = [NSMutableArray array];
    for (FLEXAppKitViewSnapshot *child in view.children) {
        [children addObject:[self dictionaryForView:child]];
    }
    return @{ @"class": orNull(view.className),
              @"superclasses": view.superclasses ?: @[],
              @"frame": rectDict(view.frame),
              @"frameTopLeft": rectDict(view.frameTopLeft),
              @"isFlipped": @(view.isFlipped),
              @"hidden": @(view.hidden),
              @"alpha": num1(view.alpha),
              @"identifier": orNull(view.identifier),
              @"text": orNull(view.text),
              @"axRole": orNull(view.axRole),
              @"font": [self fontDict:view.font],
              @"material": orNull(view.material),
              @"blendingMode": orNull(view.blendingMode),
              @"layer": [self layerDict:view.layer],
              @"constraintsCount": @(view.constraintsCount),
              @"swiftUIBoundary": @(view.swiftUIBoundary),
              @"childCount": @(view.childCount),
              @"truncated": @(view.truncated),
              @"children": children };
}

+ (NSDictionary *)dictionaryForWindow:(FLEXAppKitWindowSnapshot *)window {
    NSMutableArray *childWindows = [NSMutableArray array];
    for (FLEXAppKitWindowSnapshot *child in window.childWindows) {
        [childWindows addObject:[self dictionaryForWindow:child]];
    }
    return @{ @"class": orNull(window.className),
              @"title": orNull(window.title),
              @"identifier": orNull(window.identifier),
              @"isKeyWindow": @(window.isKeyWindow),
              @"isMainWindow": @(window.isMainWindow),
              @"isVisible": @(window.isVisible),
              @"isPanel": @(window.isPanel),
              @"frame": rectDict(window.frame),
              @"contentView": window.contentView ? [self dictionaryForView:window.contentView] : [NSNull null],
              @"childWindows": childWindows };
}

+ (NSArray<NSDictionary *> *)dictionariesForWindows:(NSArray<FLEXAppKitWindowSnapshot *> *)windows {
    NSMutableArray *result = [NSMutableArray array];
    for (FLEXAppKitWindowSnapshot *window in windows) {
        [result addObject:[self dictionaryForWindow:window]];
    }
    return result;
}

+ (id)constraintItemDict:(FLEXConstraintItem *)item {
    return @{ @"class": orNull(item.className),
              @"attribute": orNull(item.attribute),
              @"kind": orNull(item.kind),
              @"isTarget": @(item.isTarget) };
}

+ (NSDictionary *)dictionaryForConstraintNode:(FLEXConstraintNode *)node {
    NSMutableArray *constraints = [NSMutableArray array];
    for (FLEXConstraint *c in node.constraints) {
        [constraints addObject:@{ @"first": [self constraintItemDict:c.first],
                                  @"relation": orNull(c.relation),
                                  @"second": [self constraintItemDict:c.second],
                                  @"multiplier": num1(c.multiplier),
                                  @"constant": num1(c.constant),
                                  @"priority": num1(c.priority),
                                  @"active": @(c.active),
                                  @"identifier": orNull(c.identifier) }];
    }
    return @{ @"translatesAutoresizingMaskIntoConstraints": @(node.translatesAutoresizingMaskIntoConstraints),
              @"intrinsicContentSize": @{ @"w": num1(node.intrinsicContentSize.width),
                                          @"h": num1(node.intrinsicContentSize.height) },
              @"hugging": @{ @"horizontal": num1(node.huggingHorizontal),
                             @"vertical": num1(node.huggingVertical) },
              @"compressionResistance": @{ @"horizontal": num1(node.compressionResistanceHorizontal),
                                           @"vertical": num1(node.compressionResistanceVertical) },
              @"constraints": constraints };
}

@end

#endif // TARGET_OS_OSX
