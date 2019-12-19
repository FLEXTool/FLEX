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

@end
