//
//  FLEXViewShortcuts.m
//  FLEX
//
//  Created by Tanner Bennett on 12/11/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import "FLEXViewShortcuts.h"
#import "FLEXShortcut.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXImagePreviewViewController.h"

@interface FLEXViewShortcuts ()
@property (nonatomic, readonly) UIView *view;
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

+ (UIViewController *)nearestViewControllerForView:(UIView *)view {
    return [self viewControllerForView:view] ?: [self viewControllerForAncestralView:view];
}

+ (UIViewController *)imagePreviewViewControllerForView:(UIView *)view {
    if (!CGRectIsEmpty(view.bounds)) {
        CGSize viewSize = view.bounds.size;
        UIGraphicsBeginImageContextWithOptions(viewSize, NO, 0.0);
        [view drawViewHierarchyInRect:CGRectMake(0, 0, viewSize.width, viewSize.height) afterScreenUpdates:YES];
        UIImage *previewImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return [FLEXImagePreviewViewController forImage:previewImage];
    }

    return nil;
}

#pragma mark - Overrides

+ (instancetype)forObject:(UIView *)view {
    // In the past, FLEX would not hold a strong reference to something like this.
    // After using FLEX for so long, I am certain it is more useful to eagerly
    // reference something as useful as a view controller so that the reference
    // is not lost and swept out from under you before you can access it.
    //
    // The alternative here is to use a future in place of `controller` which would
    // dynamically grab a reference to the view controller. 99% of the time, however,
    // it is not all that useful. If you need it to refresh, you can simply go back
    // and go forward again and it will show if the view controller is nil or changed.
    UIViewController *controller = [FLEXViewShortcuts nearestViewControllerForView:view];

    return [self forObject:view additionalRows:@[
        [FLEXActionShortcut title:@"Nearest View Controller"
            subtitle:^NSString *(id view) {
                return [FLEXRuntimeUtility safeDescriptionForObject:controller];
            }
            viewer:^UIViewController *(id view) {
                return [FLEXObjectExplorerFactory explorerViewControllerForObject:controller];
            }
            accessoryType:^UITableViewCellAccessoryType(id view) {
                return controller ? UITableViewCellAccessoryDisclosureIndicator : 0;
            }
        ],
        [FLEXActionShortcut title:@"Preview Image" subtitle:nil
            viewer:^UIViewController *(id view) {
                return [FLEXViewShortcuts imagePreviewViewControllerForView:view];
            }
            accessoryType:^UITableViewCellAccessoryType(id view) {
                return UITableViewCellAccessoryDisclosureIndicator;
            }
        ]
    ]];
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
