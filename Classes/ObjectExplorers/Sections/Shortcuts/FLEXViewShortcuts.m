//
//  FLEXViewShortcuts.m
//  FLEX
//
//  Created by Tanner Bennett on 12/11/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import "FLEXViewShortcuts.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXImagePreviewViewController.h"

@interface FLEXViewShortcuts ()
@property (nonatomic, readonly) UIView *view;
@property (nonatomic, readonly) BOOL showsViewControllerRow;
@end

@implementation FLEXViewShortcuts

#pragma mark - Internal

- (UIView *)view {
    return self.object;
}

+ (UIViewController *)viewControllerForView:(UIView *)view {
    NSString *viewDelegate = @"viewDelegate";
    if ([view respondsToSelector:NSSelectorFromString(viewDelegate)]) {
        return [view valueForKey:viewDelegate];
    }

    return nil;
}

+ (UIViewController *)viewControllerForAncestralView:(UIView *)view {
    NSString *_viewControllerForAncestor = @"_viewControllerForAncestor";
    if ([view respondsToSelector:NSSelectorFromString(_viewControllerForAncestor)]) {
        return [view valueForKey:_viewControllerForAncestor];
    }

    return nil;
}

- (UIViewController *)viewControllerForView {
    return [[self class] viewControllerForView:self.view] ?:
        [[self class] viewControllerForAncestralView:self.view];
}

- (UIViewController *)imagePreviewViewController {
    if (!CGRectIsEmpty(self.view.bounds)) {
        CGSize viewSize = self.view.bounds.size;
        UIGraphicsBeginImageContextWithOptions(viewSize, NO, 0.0);
        [self.view drawViewHierarchyInRect:CGRectMake(0, 0, viewSize.width, viewSize.height) afterScreenUpdates:YES];
        UIImage *previewImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return [FLEXImagePreviewViewController forImage:previewImage];
    }

    return nil;
}

#pragma mark - Overrides

+ (instancetype)forObject:(UIView *)view {
    // Views without a superview don't need the "View Controller for Ancestor" row
    BOOL hasViewController = [self viewControllerForView:view] != nil;
    BOOL hasAncestralVC = [self viewControllerForAncestralView:view] != nil;
    NSString *vcRowTitle = hasViewController ? @"View Controller" :
        hasAncestralVC ? @"View Controller for Ancestor" : nil;

    // These additional rows will appear at the beginning of the shortcuts section.
    // The methods below are written in such a way that they will not interfere
    // with properties/etc being registered alongside these
    FLEXViewShortcuts *shortcuts = [self forObject:view additionalRows:(
        vcRowTitle ? @[vcRowTitle, @"Preview"] : @[@"Preview"]
    )];
    shortcuts->_showsViewControllerRow = hasViewController || hasAncestralVC;
    return shortcuts;
}

- (UIViewController *)viewControllerToPushForRow:(NSInteger)row {
    switch (row) {
        case 0:
            if (self.showsViewControllerRow) {
                return [FLEXObjectExplorerFactory
                    explorerViewControllerForObject:[self viewControllerForView]
                ];
            } else {
                return [self imagePreviewViewController];
            }
        case 1:
            if (self.showsViewControllerRow) {
                return [self imagePreviewViewController];
            }

        default:
            return [super viewControllerToPushForRow:row];
    }
}


#pragma mark - Runtime Adjustment

#define PropertyKey(suffix) kFLEXPropertyAttributeKey##suffix : @""
#define PropertyKeyGetter(getter) kFLEXPropertyAttributeKeyCustomGetter : NSStringFromSelector(@selector(getter))
#define PropertyKeySetter(setter) kFLEXPropertyAttributeKeyCustomSetter : NSStringFromSelector(@selector(setter))

/// Takes: min iOS version, property name, target class, property type, and a list of attributes
#define FLEXRuntimeUtilityTryAddProperty(iOS_atLeast, name, cls, type, ...) ({ \
    if (@available(iOS iOS_atLeast, *)) { \
        NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithDictionary:@{ \
            kFLEXPropertyAttributeKeyTypeEncoding : @(type), \
            __VA_ARGS__ \
        }]; \
        [FLEXRuntimeUtility \
            tryAddPropertyWithName:#name \
            attributes:attrs \
            toClass:[cls class] \
        ]; \
    } \
})

/// Takes: min iOS version, property name, target class, property type, and a list of attributes
#define FLEXRuntimeUtilityTryAddNonatomicProperty(iOS_atLeast, name, cls, type, ...) \
    FLEXRuntimeUtilityTryAddProperty(iOS_atLeast, name, cls, @encode(type), PropertyKey(NonAtomic), __VA_ARGS__);
/// Takes: min iOS version, property name, target class, property type (class name), and a list of attributes
#define FLEXRuntimeUtilityTryAddObjectProperty(iOS_atLeast, name, cls, type, ...) \
    FLEXRuntimeUtilityTryAddProperty(iOS_atLeast, name, cls, FLEXEncodeClass(type), PropertyKey(NonAtomic), __VA_ARGS__);

+ (void)load {
    // A quirk of UIView and some other classes: a lot of the `@property`s are
    // not actually properties from the perspective of the runtime.
    //
    // We add these properties to the class at runtime if they haven't been added yet.
    // This way, we can use our property editor to access and change them.
    // The property attributes match the declared attributes in their headers.

    // UIView, public
    FLEXRuntimeUtilityTryAddNonatomicProperty(2, frame, UIView, CGRect);
    FLEXRuntimeUtilityTryAddNonatomicProperty(2, alpha, UIView, CGFloat);
    FLEXRuntimeUtilityTryAddNonatomicProperty(2, clipsToBounds, UIView, BOOL);
    FLEXRuntimeUtilityTryAddNonatomicProperty(2, opaque, UIView, BOOL, PropertyKeyGetter(isOpaque));
    FLEXRuntimeUtilityTryAddNonatomicProperty(2, hidden, UIView, BOOL, PropertyKeyGetter(isHidden));
    FLEXRuntimeUtilityTryAddObjectProperty(2, backgroundColor, UIView, UIColor, PropertyKey(Copy));
    FLEXRuntimeUtilityTryAddObjectProperty(6, constraints, UIView, NSArray, PropertyKey(ReadOnly));
    FLEXRuntimeUtilityTryAddObjectProperty(2, subviews, UIView, NSArray, PropertyKey(ReadOnly));
    FLEXRuntimeUtilityTryAddObjectProperty(2, superview, UIView, UIView, PropertyKey(ReadOnly));

    // UIButton, private
    FLEXRuntimeUtilityTryAddObjectProperty(2, font, UIButton, UIFont, PropertyKey(ReadOnly));
}

@end
