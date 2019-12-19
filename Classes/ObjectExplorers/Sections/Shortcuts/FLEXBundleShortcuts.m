//
//  FLEXBundleShortcuts.m
//  FLEX
//
//  Created by Tanner Bennett on 12/12/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import "FLEXBundleShortcuts.h"
#import "FLEXFileBrowserTableViewController.h"

@implementation FLEXBundleShortcuts
#pragma mark - Overrides

+ (instancetype)forObject:(NSBundle *)bundle {
    return [self forObject:bundle additionalRows:@[@"Browse bundle directory"]];
}

- (UIViewController *)viewControllerToPushForRow:(NSInteger)row {
    if (row == 0) {
        return [FLEXFileBrowserTableViewController path:[self.object bundlePath]];
    }

    return [super viewControllerToPushForRow:row];
}

@end
