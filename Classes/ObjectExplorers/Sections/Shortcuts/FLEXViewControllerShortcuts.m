//
//  FLEXViewControllerShortcuts.m
//  FLEX
//
//  Created by Tanner Bennett on 12/12/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import "FLEXViewControllerShortcuts.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXShortcut.h"
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
    BOOL (^vcIsInuse)(UIViewController *) = ^BOOL(UIViewController *controller) {
        if (controller.viewIfLoaded.window) {
            return YES;
        }

        return controller.navigationController != nil;
    };
    
    return [self forObject:viewController additionalRows:@[
        [FLEXActionShortcut title:@"Push View Controller"
            subtitle:^NSString *(UIViewController *controller) {
                return vcIsInuse(controller) ? @"In use, cannot push" : nil;
            }
            selectionHandler:^void(UIViewController *host, UIViewController *controller) {
                if (!vcIsInuse(controller)) {
                    [host.navigationController pushViewController:controller animated:YES];
                } else {
                    [FLEXAlert
                        showAlert:@"Cannot Push View Controller"
                        message:@"This view controller's view is currently in use."
                        from:host
                    ];
                }
            }
            accessoryType:^UITableViewCellAccessoryType(UIViewController *controller) {
                if (!vcIsInuse(controller)) {
                    return UITableViewCellAccessoryDisclosureIndicator;
                } else {
                    return UITableViewCellAccessoryNone;
                }
            }
        ]
    ]];
}

@end
