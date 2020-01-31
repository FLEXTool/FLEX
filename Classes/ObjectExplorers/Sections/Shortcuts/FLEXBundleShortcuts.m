//
//  FLEXBundleShortcuts.m
//  FLEX
//
//  Created by Tanner Bennett on 12/12/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import "FLEXBundleShortcuts.h"
#import "FLEXShortcut.h"
#import "FLEXFileBrowserTableViewController.h"

#pragma mark -
@implementation FLEXBundleShortcuts
#pragma mark Overrides

+ (instancetype)forObject:(NSBundle *)bundle {
    return [self forObject:bundle additionalRows:@[
        [FLEXActionShortcut title:@"Browse Bundle Directory" subtitle:nil
            viewer:^UIViewController *(id view) {
                return [FLEXFileBrowserTableViewController path:bundle.bundlePath];
            }
            accessoryType:^UITableViewCellAccessoryType(id view) {
                return UITableViewCellAccessoryDisclosureIndicator;
            }
        ]
    ]];
}

@end
