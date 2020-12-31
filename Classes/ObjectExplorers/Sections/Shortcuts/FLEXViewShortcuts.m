//
//  FLEXViewShortcuts.m
//  FLEX
//
//  Created by Tanner Bennett on 12/11/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
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
                return controller ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
            }
        ],
        [FLEXActionShortcut title:@"Preview Image" subtitle:^NSString *(UIView *view) {
                return !CGRectIsEmpty(view.bounds) ? @"" : @"Unavailable with empty bounds";
            }
            viewer:^UIViewController *(UIView *view) {
                return [FLEXImagePreviewViewController previewForView:view];
            }
            accessoryType:^UITableViewCellAccessoryType(UIView *view) {
                // Disable preview if bounds are CGRectZero
                return !CGRectIsEmpty(view.bounds) ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
            }
        ]
    ]];
}

@end
