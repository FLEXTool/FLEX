//
//  FLEXExplorerSection.m
//  FLEX
//
//  Created by Tanner Bennett on 8/28/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import "FLEXExplorerSection.h"
#import "FLEXTableView.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"

@implementation FLEXExplorerSection

- (void)reloadData { }

- (NSDictionary<NSString *,Class> *)cellRegistrationMapping {
    return nil;
}

- (BOOL)canSelectRow:(NSInteger)row { return NO; }

- (void (^)(UIViewController *))didSelectRowAction:(NSInteger)row {
    UIViewController *toPush = [self viewControllerToPushForRow:row];
    if (toPush) {
        return ^(UIViewController *host) {
            [host.navigationController pushViewController:toPush animated:YES];
        };
    }

    return nil;
}

- (UIViewController *)viewControllerToPushForRow:(NSInteger)row {
    return nil;
}

- (void (^)(UIViewController *))didPressInfoButtonAction:(NSInteger)row {
    return nil;
}

- (NSString *)reuseIdentifierForRow:(NSInteger)row {
    return kFLEXDefaultCell;
}

- (NSString *)titleForRow:(NSInteger)row { return nil; }
- (NSString *)subtitleForRow:(NSInteger)row { return nil; }

@end

#pragma clang diagnostic pop
