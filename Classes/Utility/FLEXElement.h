//
//  FLEXElement.h
//  FLEX
//
//  Created by Levi McCallum on 12/23/16.
//  Copyright © 2016 Flipboard. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, FLEXElementType) {
    FLEXElementTypeNone,
    FLEXElementTypeView,
    FLEXElementTypeNode,
};

@interface FLEXElement : NSObject

/// The backing object — either a UIView or an ASDisplayNode
@property (nonatomic, strong, readonly) id object;

///The type of object this element represents
@property (nonatomic, assign, readonly) FLEXElementType type;

/// Convenience property to access the backing object's view.
@property (nonatomic, strong, readonly) UIView *view;

/// Convenience property to access the backing object's layer.
@property (nonatomic, strong, readonly) CALayer *layer;

/// Convenience property to access the backing object's view or layer if we're dealing with a layer-backed node.
@property (nonatomic, strong, readonly) id layerOrView;

/// Convenience property to access the backing object's view or layer if we're dealing with a layer-backed node.
@property (nonatomic, assign, readonly) BOOL isLayerBacked;

/// A passthough accessor to the view's superview or node's supernode
@property (nonatomic, assign, readonly) FLEXElement *parent;

/// Array of elements each representing the backing view's subview or a node's subnodes
@property (nonatomic, strong, readonly) NSArray<FLEXElement *> *subelements;

/// Determines if the view or node is invisible on screen (isHidden == NO or alpha < 0.01)
@property (nonatomic, assign, readonly) BOOL isInvisible;

/// Provide a consistent random color for this element's backing object
@property (nonatomic, strong, readonly) UIColor *color;

/// Direct passthrough to the backing object's (view or node) frame value
@property (nonatomic, assign) CGRect frame;

/// Direct passthrough to the backing object's (view or node) bounds value
@property (nonatomic, assign, readonly) CGRect bounds;

/// Direct passthrough to the backing object's (view or node) clipsToBounds value
@property (nonatomic, assign, readonly) BOOL clipsToBounds;

/// Direct passthrough to the backing object's (view or node) accessibility label value
@property (nonatomic, strong, readonly) NSString *accessibilityLabel;

- (instancetype)initWithObject:(id)object type:(FLEXElementType)type NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (CGPoint)convertPoint:(CGPoint)point toElement:(FLEXElement *)element;

- (NSString *)descriptionIncludingFrame:(BOOL)frame;
- (NSString *)detailDescription;

@end
