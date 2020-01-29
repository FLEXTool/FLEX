//
//  FLEXViewControllerShortcuts.m
//  FLEX
//
//  Created by Tanner Bennett on 12/12/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import "FLEXViewControllerShortcuts.h"
#import "FLEXAlert.h"

@interface FLEXViewControllerShortcuts ()
@property (nonatomic, readonly) UIViewController *viewController;
@property (nonatomic, readonly) BOOL viewControllerIsInUse;
@end

@implementation FLEXViewControllerShortcuts

#pragma mark - Internal

- (UIViewController *)viewController {
    return self.object;
}

/// A view controller is "in use" if it's view is in a window,
/// or if it belongs to a navigation stack which is in use.
- (BOOL)viewControllerIsInUse {
    if (self.viewController.view.window) {
        return YES;
    }

    return self.viewController.navigationController != nil;
}


#pragma mark - Overrides

+ (instancetype)forObject:(UIViewController *)viewController {
    // These additional rows will appear at the beginning of the shortcuts section.
    // The methods below are written in such a way that they will not interfere
    // with properties/etc being registered alongside these
    return [self forObject:viewController additionalRows:@[@"Push View Controoller"]];
}

- (void (^)(__kindof UIViewController *))didSelectRowAction:(NSInteger)row {
    if (row == 0) {
        return ^(UIViewController *host) {
            if (!self.viewControllerIsInUse) {
                [host.navigationController pushViewController:self.viewController animated:YES];
            } else {
                [FLEXAlert
                    showAlert:@"Cannot Push View Controller"
                    message:@"This view controller's view is currently in use."
                    from:host
                ];
            }
        };
    }

    return [super didSelectRowAction:row];
}

- (UITableViewCellAccessoryType)accessoryTypeForRow:(NSInteger)row {
    switch (row) {
        case 0:
            if (self.viewControllerIsInUse) {
                return UITableViewCellAccessoryDisclosureIndicator;
            } else {
                return UITableViewCellAccessoryNone;
            }
        default:
            return [super accessoryTypeForRow:row];
    }
}

@end
