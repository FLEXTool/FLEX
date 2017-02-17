//
//  FLEXElement.m
//  FLEX
//
//  Created by Levi McCallum on 12/23/16.
//  Copyright © 2016 Flipboard. All rights reserved.
//

#import "FLEXUtility.h"

#import "FLEXElement.h"

typedef NS_ENUM(NSUInteger, FLEXElementNodeType) {
    FLEXElementNodeTypeNone,
    FLEXElementNodeTypeRegular,
    FLEXElementNodeTypeContainer,
    FLEXElementNodeTypeCell,
};

@interface FLEXElement ()

@property (nonatomic, assign, readonly) FLEXElementNodeType nodeType;

@end

@implementation FLEXElement

- (instancetype)initWithObject:(id)object type:(FLEXElementType)type
{
    if (self = [super init]) {
        _object = object;
        _type = type;

        if (type == FLEXElementTypeNode) {
            _nodeType = [[self class] nodeTypeForNode:object];
        } else {
            _nodeType = FLEXElementNodeTypeNone;
        }
    }
    return self;
}

- (instancetype)initWithChildObject:(id)object parent:(FLEXElement *)parent
{
    FLEXElementType type = parent.type;
    id backingNode = nil;

    // Container node children see their parent as a view, as ascellnodes are not direct children of their container
    // In order to preserve levels in between container and cell nodes — ie. contentView and the uiview cell itself, container nodes provide their subviews instead of subnodes as FLEXElement.children and let the backing node logic below convert the subview into a node if it really is one
    if (parent.nodeType == FLEXElementNodeTypeContainer) {
        type = FLEXElementTypeView;
    }

    // Switch to the node hierarchy if the subview has a backing node
    backingNode = [[self class] nodeForView:object];
    if (backingNode != nil) {
        object = backingNode;
        type = FLEXElementTypeNode;
    }
    return [self initWithObject:object type:type];
}

- (CGPoint)convertPoint:(CGPoint)point toElement:(FLEXElement *)element
{
    if (self.type == FLEXElementTypeView ||
        element.type == FLEXElementTypeView ||
        // stab in the dark, as we can't say that a container view has the same hierarchy as its cells
        self.nodeType == FLEXElementNodeTypeContainer) {
        return [self.view convertPoint:point toView:element.view];
    } else {
        SEL selector = NSSelectorFromString(@"convertPoint:toNode:");
        Class nodeClass = NSClassFromString(@"ASDisplayNode");
        NSMethodSignature *sig = [nodeClass instanceMethodSignatureForSelector:selector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
        invocation.target = self.object;
        invocation.selector = selector;
        [invocation setArgument:&point atIndex:2];
        id node = element.object;
        [invocation setArgument:&node atIndex:3];
        [invocation invoke];
        CGPoint returnValue;
        [invocation getReturnValue:&returnValue];
        return returnValue;
    }
}

- (NSString *)descriptionIncludingFrame:(BOOL)frame
{
    NSString *description = [[self.object class] description];
    
    if (self.type == FLEXElementTypeView) {
        NSString *viewControllerDescription = [[[FLEXUtility viewControllerForView:self.view] class] description];
        if ([viewControllerDescription length] > 0) {
            description = [description stringByAppendingFormat:@" (%@)", viewControllerDescription];
        }        
    }
    
    if (frame) {
        description = [description stringByAppendingFormat:@" %@", [FLEXUtility stringForCGRect:self.frame]];
    }
    
    NSString *label = self.accessibilityLabel;
    if ([label length] > 0) {
        description = [description stringByAppendingFormat:@" · %@", label];
    }
    
    return description;
}

- (NSString *)detailDescription
{
    NSString *base = [NSString stringWithFormat:@"frame %@", [FLEXUtility stringForCGRect:self.frame]];
    if (self.type == FLEXElementTypeNode) {
        NSString *type = self.isLayerBacked ? @"layer" : @"view";
        base = [NSString stringWithFormat:@"%@ - %@", type, base];
    }
    return base;
}

#pragma mark - Accessors

- (UIView *)view
{
    if (self.type == FLEXElementTypeView) {
        return self.object;
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        return [self.object performSelector:NSSelectorFromString(@"view")];
#pragma clang diagnostic pop
    }
}

- (CALayer *)layer
{
    if (self.type == FLEXElementTypeView) {
        return [(UIView *)self.object layer];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        return [self.object performSelector:NSSelectorFromString(@"layer")];
#pragma clang diagnostic pop
    }
}

- (id)layerOrView
{
    if (self.type == FLEXElementTypeView) {
        return self.object;
    } else if (self.type == FLEXElementTypeNode) {
        NSString *selectorString = self.isLayerBacked ? @"layer" : @"view";
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        return [self.object performSelector:NSSelectorFromString(selectorString)];
#pragma clang diagnostic pop
    }

    return nil;
}

- (BOOL)isLayerBacked
{
    if (self.type == FLEXElementTypeNode) {
        NSInvocation *invocation = [self _invocationWithStringSelector:@"isLayerBacked"];
        [invocation invoke];
        BOOL isLayerBacked = NO;
        [invocation getReturnValue:&isLayerBacked];
        return isLayerBacked;
    }
    return NO;
}

- (FLEXElement *)parent
{
    if (self.type == FLEXElementTypeNone) {
        return nil;
    }
    
    // Cell nodes are hosted in a cell view. In order to include this cell in hierarchy output, call to the cell's
    // superview (UICollection/TableViewCell), instead of supernode (Collection/TableNode)
    if (self.type == FLEXElementTypeNode && self.nodeType != FLEXElementNodeTypeCell) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        id supernode = [self.object performSelector:NSSelectorFromString(@"supernode")];
#pragma clang diagnostic pop
        // If the node is the root of the hierarchy, supernode will be nil and the node's superview should be used
        if (supernode != nil) {
            return [[[self class] alloc] initWithObject:supernode type:FLEXElementTypeNode];
        }
    }
    
    id superview = self.view.superview;
    if (superview != nil) {
        FLEXElementType type = FLEXElementTypeView;
        id backingNode;
        if (self.type == FLEXElementTypeView) {
            // Jump back to the node hierarchy if the parent is a node (in the case we switched to the view hierarchy between a cell and its container node)
            backingNode = [[self class] nodeForView:superview];
            if (backingNode != nil) {
                superview = backingNode;
                type = FLEXElementTypeNode;
            }
        }
        return [[[self class] alloc] initWithObject:superview type:type];
    }
    
    return nil;
}

- (NSArray<FLEXElement *> *)subelements
{
    NSMutableArray<FLEXElement *> *elements = [NSMutableArray array];
    for (id child in [self _children]) {
        FLEXElement *element = [[[self class] alloc] initWithChildObject:child parent:self];
        [elements addObject:element];
    }
    return elements;
}

- (BOOL)isInvisible
{
    return [self _isHidden] || [self _alpha] < 0.01;
}

- (UIColor *)color
{
    return [FLEXUtility consistentRandomColorForObject:self.object];
}

- (CGRect)frame
{
    if (self.type == FLEXElementTypeView) {
        return ((UIView *)self.object).frame;
    } else {
        NSInvocation *invocation = [self _invocationWithStringSelector:@"frame"];
        [invocation invoke];
        CGRect returnValue;
        [invocation getReturnValue:&returnValue];
        return returnValue;
    }
}

- (void)setFrame:(CGRect)frame
{
    if (self.type == FLEXElementTypeView) {
        [((UIView *)self.object) setFrame:frame];
    } else {
        NSInvocation *invocation = [self _invocationWithStringSelector:@"setFrame:"];
        [invocation setArgument:&frame atIndex:2];
        [invocation invoke];
    }
}

- (CGRect)bounds
{
    if (self.type == FLEXElementTypeView) {
        return ((UIView *)self.object).bounds;
    } else {
        NSInvocation *invocation = [self _invocationWithStringSelector:@"bounds"];
        [invocation invoke];
        CGRect returnValue;
        [invocation getReturnValue:&returnValue];
        return returnValue;
    }
}

- (BOOL)clipsToBounds
{
    if (self.type == FLEXElementTypeView) {
        return ((UIView *)self.object).clipsToBounds;
    } else {
        NSInvocation *invocation = [self _invocationWithStringSelector:@"clipsToBounds"];
        [invocation invoke];
        BOOL returnValue;
        [invocation getReturnValue:&returnValue];
        return returnValue;
    }
}

- (NSString *)accessibilityLabel
{
    if (self.type == FLEXElementTypeView) {
        return self.view.accessibilityLabel;
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        return [self.object performSelector:NSSelectorFromString(@"accessibilityLabel")];
#pragma clang diagnostic pop
    }
}

#pragma mark - Private

- (NSArray *)_children
{
    // For container nodes (collections, tables, pager), use the view hierachy to get an accurate
    // picture of cells on screen.
    if (self.type == FLEXElementTypeNode && self.nodeType != FLEXElementNodeTypeContainer) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        return [self.object performSelector:NSSelectorFromString(@"subnodes")];
#pragma clang diagnostic pop
    }
    
    return self.view.subviews;
}

- (CGFloat)_alpha
{
    if (self.type == FLEXElementTypeView) {
        return ((UIView *)self.object).alpha;
    } else {
        NSInvocation *invocation = [self _invocationWithStringSelector:@"alpha"];
        [invocation invoke];
        CGFloat returnValue;
        [invocation getReturnValue:&returnValue];
        return returnValue;
    }
}

- (BOOL)_isHidden
{
    if (self.type == FLEXElementTypeView) {
        return ((UIView *)self.object).isHidden;
    } else {
        NSInvocation *invocation = [self _invocationWithStringSelector:@"isHidden"];
        [invocation invoke];
        BOOL returnValue;
        [invocation getReturnValue:&returnValue];
        return returnValue;
    }
}

- (NSInvocation *)_invocationWithStringSelector:(NSString *)stringSelector
{
    SEL selector = NSSelectorFromString(stringSelector);
    Class nodeClass = NSClassFromString(@"ASDisplayNode");
    NSMethodSignature *sig = [nodeClass instanceMethodSignatureForSelector:selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
    invocation.target = self.object;
    invocation.selector = selector;
    return invocation;
}

+ (id)nodeForView:(id)view
{
    if ([view isKindOfClass:NSClassFromString(@"_ASDisplayView")] ||
        [view isKindOfClass:NSClassFromString(@"_ASCollectionView")] ||
        [view isKindOfClass:NSClassFromString(@"_ASTableView")]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        return [view performSelector:NSSelectorFromString(@"asyncdisplaykit_node")];
#pragma clang diagnostic pop
    }
    return nil;
}

+ (FLEXElementNodeType)nodeTypeForNode:(id)node
{
    if ([node isKindOfClass:NSClassFromString(@"ASCellNode")]) {
        return FLEXElementNodeTypeCell;
    }
    
    for (NSString *containerClass in [self containerNodeClasses]) {
        Class objectClass = NSClassFromString(containerClass);
        if ([node isKindOfClass:objectClass]) {
            return FLEXElementNodeTypeContainer;
            break;
        }
    }
    
    return FLEXElementNodeTypeRegular;
}

+ (NSArray *)containerNodeClasses
{
    static NSArray *containerNodeClasses = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        containerNodeClasses = @[@"ASCollectionNode", @"ASTableNode", @"ASPagerNode"];
    });
    return containerNodeClasses;
}

@end
