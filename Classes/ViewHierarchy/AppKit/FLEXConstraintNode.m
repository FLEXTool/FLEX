//
//  FLEXConstraintNode.m
//  FLEX
//
//  SPEC: domain.walker
//

#import "FLEXConstraintNode.h"

#if TARGET_OS_OSX

#import <AppKit/AppKit.h>
#import <objc/runtime.h>

static NSString *FLEXAttrName(NSLayoutAttribute attr) {
    switch (attr) {
        case NSLayoutAttributeLeft: return @"left";
        case NSLayoutAttributeRight: return @"right";
        case NSLayoutAttributeTop: return @"top";
        case NSLayoutAttributeBottom: return @"bottom";
        case NSLayoutAttributeLeading: return @"leading";
        case NSLayoutAttributeTrailing: return @"trailing";
        case NSLayoutAttributeWidth: return @"width";
        case NSLayoutAttributeHeight: return @"height";
        case NSLayoutAttributeCenterX: return @"centerX";
        case NSLayoutAttributeCenterY: return @"centerY";
        case NSLayoutAttributeLastBaseline: return @"lastBaseline";
        case NSLayoutAttributeFirstBaseline: return @"firstBaseline";
        case NSLayoutAttributeNotAnAttribute: return @"notAnAttribute";
        default: return [NSString stringWithFormat:@"attr(%ld)", (long)attr];
    }
}

static NSString *FLEXRelationName(NSLayoutRelation relation) {
    switch (relation) {
        case NSLayoutRelationLessThanOrEqual: return @"lessThanOrEqual";
        case NSLayoutRelationEqual: return @"equal";
        case NSLayoutRelationGreaterThanOrEqual: return @"greaterThanOrEqual";
        default: return [NSString stringWithFormat:@"relation(%ld)", (long)relation];
    }
}

#pragma mark -

@interface FLEXConstraintItem ()
@property (nonatomic, copy, nullable) NSString *className;
@property (nonatomic, copy) NSString *attribute;
@property (nonatomic, copy) NSString *kind;
@property (nonatomic) BOOL isTarget;
@end

@implementation FLEXConstraintItem

+ (FLEXConstraintItem *)itemFor:(nullable id)item
                      attribute:(NSLayoutAttribute)attribute
                         target:(NSView *)target {
    FLEXConstraintItem *result = [FLEXConstraintItem new];
    result.attribute = FLEXAttrName(attribute);
    if (item == nil) {
        result.kind = @"none";
        return result;
    }
    result.className = NSStringFromClass(object_getClass(item));
    result.isTarget = (item == target);
    if ([item isKindOfClass:[NSView class]]) {
        result.kind = @"view";
    } else if ([item isKindOfClass:[NSLayoutGuide class]]) {
        result.kind = @"layoutGuide";
    } else {
        result.kind = @"other";
    }
    return result;
}

@end

#pragma mark -

@interface FLEXConstraint ()
@property (nonatomic) FLEXConstraintItem *first;
@property (nonatomic, copy) NSString *relation;
@property (nonatomic) FLEXConstraintItem *second;
@property (nonatomic) double multiplier;
@property (nonatomic) double constant;
@property (nonatomic) double priority;
@property (nonatomic) BOOL active;
@property (nonatomic, copy, nullable) NSString *identifier;
@end

@implementation FLEXConstraint

+ (FLEXConstraint *)constraintFrom:(NSLayoutConstraint *)constraint target:(NSView *)target {
    FLEXConstraint *result = [FLEXConstraint new];
    result.first = [FLEXConstraintItem itemFor:constraint.firstItem
                                     attribute:constraint.firstAttribute
                                        target:target];
    result.relation = FLEXRelationName(constraint.relation);
    result.second = [FLEXConstraintItem itemFor:constraint.secondItem
                                      attribute:constraint.secondAttribute
                                         target:target];
    result.multiplier = constraint.multiplier;
    result.constant = constraint.constant;
    result.priority = constraint.priority;
    result.active = constraint.isActive;
    result.identifier = constraint.identifier;
    return result;
}

@end

#pragma mark -

@interface FLEXConstraintNode ()
@property (nonatomic) BOOL translatesAutoresizingMaskIntoConstraints;
@property (nonatomic) CGSize intrinsicContentSize;
@property (nonatomic) double huggingHorizontal;
@property (nonatomic) double huggingVertical;
@property (nonatomic) double compressionResistanceHorizontal;
@property (nonatomic) double compressionResistanceVertical;
@property (nonatomic, copy) NSArray<FLEXConstraint *> *constraints;
@end

@implementation FLEXConstraintNode

+ (instancetype)constraintsForView:(NSView *)view {
    FLEXConstraintNode *node = [FLEXConstraintNode new];
    node.translatesAutoresizingMaskIntoConstraints = view.translatesAutoresizingMaskIntoConstraints;
    node.intrinsicContentSize = view.intrinsicContentSize;
    node.huggingHorizontal =
        [view contentHuggingPriorityForOrientation:NSLayoutConstraintOrientationHorizontal];
    node.huggingVertical =
        [view contentHuggingPriorityForOrientation:NSLayoutConstraintOrientationVertical];
    node.compressionResistanceHorizontal =
        [view contentCompressionResistancePriorityForOrientation:NSLayoutConstraintOrientationHorizontal];
    node.compressionResistanceVertical =
        [view contentCompressionResistancePriorityForOrientation:NSLayoutConstraintOrientationVertical];

    NSMutableArray<FLEXConstraint *> *out = [NSMutableArray array];
    NSMutableSet *seen = [NSMutableSet set];

    void (^collect)(NSArray<NSLayoutConstraint *> *, BOOL) =
        ^(NSArray<NSLayoutConstraint *> *constraints, BOOL requireTouch) {
            for (NSLayoutConstraint *constraint in constraints) {
                if (![constraint isKindOfClass:[NSLayoutConstraint class]]) {
                    continue;
                }
                if (requireTouch
                    && constraint.firstItem != view
                    && constraint.secondItem != view) {
                    continue;
                }
                NSValue *box = [NSValue valueWithNonretainedObject:constraint];
                if ([seen containsObject:box]) {
                    continue;
                }
                [seen addObject:box];
                [out addObject:[FLEXConstraint constraintFrom:constraint target:view]];
            }
        };

    // Constraints that TOUCH this view (first or second item), in both directions:
    // its own constraints that reference it, plus any ancestor-held constraint that
    // references it (AppKit has no public reverse index). A view also holds
    // constraints purely between its descendants — those don't touch it and are
    // excluded, matching the spec's "constraints that touch it".
    collect(view.constraints, YES);
    for (NSView *ancestor = view.superview; ancestor != nil; ancestor = ancestor.superview) {
        collect(ancestor.constraints, YES);
    }
    node.constraints = out;
    return node;
}

@end

#endif // TARGET_OS_OSX
