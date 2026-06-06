//
//  FLEXConstraintNode.h
//  FLEX
//
//  Auto Layout extraction for one view: every NSLayoutConstraint touching it in
//  BOTH directions (where it is the first item and the second item), serialized as
//  first.attr (relation) second.attr * multiplier + constant @ priority, plus the
//  node's intrinsic-sizing facts. NSLayoutConstraint is the same class on macOS and
//  iOS, so this is cross-platform.
//
//  Node-id stringification of each item is the server's concern; this captures the
//  AppKit facts + each item's class and role (target / view / layoutGuide / none).
//
//  SPEC: domain.walker
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@class NSView;

NS_ASSUME_NONNULL_BEGIN

/// One side of a constraint.
@interface FLEXConstraintItem : NSObject
/// Runtime class of the item; nil for the absent second item of a constant constraint.
@property (nonatomic, readonly, copy, nullable) NSString *className;
/// "leading" / "width" / "notAnAttribute" ...
@property (nonatomic, readonly, copy) NSString *attribute;
/// "view" | "layoutGuide" | "other" | "none"
@property (nonatomic, readonly, copy) NSString *kind;
/// True when this item is the view the FLEXConstraintNode describes.
@property (nonatomic, readonly) BOOL isTarget;
@end

@interface FLEXConstraint : NSObject
@property (nonatomic, readonly) FLEXConstraintItem *first;
@property (nonatomic, readonly, copy) NSString *relation; // "lessThanOrEqual"/"equal"/"greaterThanOrEqual"
@property (nonatomic, readonly) FLEXConstraintItem *second;
@property (nonatomic, readonly) double multiplier;
@property (nonatomic, readonly) double constant;
@property (nonatomic, readonly) double priority;
@property (nonatomic, readonly) BOOL active;
@property (nonatomic, readonly, copy, nullable) NSString *identifier;
@end

@interface FLEXConstraintNode : NSObject

/// Extract the constraints touching `view` in both directions, plus its
/// intrinsic-sizing facts. Must be called on the main thread.
+ (instancetype)constraintsForView:(NSView *)view;

@property (nonatomic, readonly) BOOL translatesAutoresizingMaskIntoConstraints;
/// Raw intrinsicContentSize; an axis with no intrinsic metric is NSViewNoIntrinsicMetric (-1).
@property (nonatomic, readonly) CGSize intrinsicContentSize;
@property (nonatomic, readonly) double huggingHorizontal;
@property (nonatomic, readonly) double huggingVertical;
@property (nonatomic, readonly) double compressionResistanceHorizontal;
@property (nonatomic, readonly) double compressionResistanceVertical;
/// The constraints touching the view, both directions, deduplicated.
@property (nonatomic, readonly, copy) NSArray<FLEXConstraint *> *constraints;

@end

NS_ASSUME_NONNULL_END
