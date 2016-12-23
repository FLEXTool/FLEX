//
//  FLEXHierarchyItem.m
//  FLEX
//
//  Created by Levi McCallum on 12/23/16.
//  Copyright © 2016 Flipboard. All rights reserved.
//

#import "FLEXUtility.h"

#import "FLEXHierarchyItem.h"


@interface FLEXHierarchyItem ()

@property (nonatomic, assign, readonly) BOOL isContainerNode;

@end

@implementation FLEXHierarchyItem

- (instancetype)initWithObject:(id)object type:(FLEXHierarchyItemType)type parentType:(FLEXHierarchyItemType)parentType
{
    if (self = [super init]) {
        _object = object;
        _type = type;
        _parentType = parentType;
        _isContainerNode = NO;

        if (type == FLEXHierarchyItemTypeNode) {
            for (NSString *containerClass in [[self class] containerNodeClasses]) {
                Class objectClass = NSClassFromString(containerClass);
                if ([object isKindOfClass:objectClass]) {
                    _isContainerNode = YES;
                    break;
                }
            }
        }
    }
    return self;
}

- (instancetype)initWithObject:(id)object type:(FLEXHierarchyItemType)type
{
    return [self initWithObject:object type:type parentType:FLEXHierarchyItemTypeNone];
}

- (instancetype)initWithChildObject:(id)object parentType:(FLEXHierarchyItemType)parentType
{
    FLEXHierarchyItemType type = parentType;
    // Switch to the node hierarchy if the subview has a backing node
    id backingNode = [[self class] nodeForView:object];
    if (backingNode != nil) {
        object = backingNode;
        type = FLEXHierarchyItemTypeNode;
    }
    return [self initWithObject:object type:type parentType:parentType];
}

- (CGPoint)convertPoint:(CGPoint)point toItem:(FLEXHierarchyItem *)item
{
    if (self.type == FLEXHierarchyItemTypeView || item.type == FLEXHierarchyItemTypeView) {
        return [self.view convertPoint:point toView:item.view];
    } else {
        SEL selector = NSSelectorFromString(@"convertPoint:toNode:");
        Class nodeClass = NSClassFromString(@"ASDisplayNode");
        NSMethodSignature *sig = [nodeClass instanceMethodSignatureForSelector:selector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
        invocation.target = self.object;
        invocation.selector = selector;
        [invocation setArgument:&point atIndex:2];
        id node = item.object;
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
    
    if (self.type == FLEXHierarchyItemTypeView) {
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
    return [NSString stringWithFormat:@"frame %@", [FLEXUtility stringForCGRect:self.frame]];
}

#pragma mark - Accessors

- (UIView *)view
{
    if (self.type == FLEXHierarchyItemTypeView) {
        return self.object;
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        return [self.object performSelector:NSSelectorFromString(@"view")];
#pragma clang diagnostic pop
    }
}

- (FLEXHierarchyItem *)parent
{
    if (self.parentType == FLEXHierarchyItemTypeView) {
        id superview = self.view.superview;
        if (superview != nil) {
            FLEXHierarchyItemType type = FLEXHierarchyItemTypeView;
            id backingNode = [[self class] nodeForView:superview];
            if (backingNode != nil) {
                superview = backingNode;
                type = FLEXHierarchyItemTypeNode;
            }
            return [[[self class] alloc] initWithObject:superview type:type];
        }
    } else if (self.parentType == FLEXHierarchyItemTypeNode) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        id supernode = [self.object performSelector:NSSelectorFromString(@"supernode")];
#pragma clang diagnostic pop
        if (supernode != nil) {
            return [[[self class] alloc] initWithObject:supernode type:FLEXHierarchyItemTypeNode];
        }
    }
    
    return nil;
}

- (NSArray<FLEXHierarchyItem *> *)subitems
{
    NSMutableArray<FLEXHierarchyItem *> *items = [NSMutableArray array];
    // Tell the children container node parents are views, such that the jump between node and view hierarchy is intact
    FLEXHierarchyItemType parentType = self.isContainerNode ? FLEXHierarchyItemTypeView : self.type;
    for (id child in [self _children]) {
        FLEXHierarchyItem *item = [[[self class] alloc] initWithChildObject:child parentType:parentType];
        [items addObject:item];
    }
    return items;
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
    if (self.type == FLEXHierarchyItemTypeView) {
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
    if (self.type == FLEXHierarchyItemTypeView) {
        [((UIView *)self.object) setFrame:frame];
    } else {
        NSInvocation *invocation = [self _invocationWithStringSelector:@"setFrame:"];
        [invocation setArgument:&frame atIndex:2];
        [invocation invoke];
    }
}

- (CGRect)bounds
{
    if (self.type == FLEXHierarchyItemTypeView) {
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
    if (self.type == FLEXHierarchyItemTypeView) {
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
    if (self.type == FLEXHierarchyItemTypeView) {
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
    if (self.type == FLEXHierarchyItemTypeNode && self.isContainerNode == NO) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        return [self.object performSelector:NSSelectorFromString(@"subnodes")];
#pragma clang diagnostic pop
    }
    
    return self.view.subviews;
}

- (CGFloat)_alpha
{
    if (self.type == FLEXHierarchyItemTypeView) {
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
    if (self.type == FLEXHierarchyItemTypeView) {
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

+ (id)nodeForView:(id)object
{
    if ([object isKindOfClass:NSClassFromString(@"_ASDisplayView")]) {
        return [object performSelector:NSSelectorFromString(@"asyncdisplaykit_node")];
    } else if ([object isKindOfClass:NSClassFromString(@"_ASCollectionViewCell")] ||
               [object isKindOfClass:NSClassFromString(@"_ASTableViewCell")]) {
        return [object performSelector:NSSelectorFromString(@"node")];
    }
    return nil;
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
