//
//  FLEXViewControllerShortcuts.m
//  FLEX
//
//  Created by Tanner Bennett on 12/12/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "Classes/ObjectExplorers/Sections/Shortcuts/FLEXViewControllerShortcuts.h"
#import "Classes/Headers/FLEXObjectExplorerFactory.h"
#import "Classes/Utility/Runtime/FLEXRuntimeUtility.h"
#import "Classes/Headers/FLEXShortcut.h"
#import "Classes/Utility/FLEXAlert.h"

@interface FLEXViewControllerShortcuts ()
@end

@implementation FLEXViewControllerShortcuts

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
