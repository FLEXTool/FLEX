//
//  FLEXClassShortcuts.m
//  FLEX
//
//  Created by Tanner Bennett on 11/22/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import "FLEXClassShortcuts.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXShortcut.h"
#import "FLEXInstancesTableViewController.h"

/// Pretty much only necessary because I want to provide
/// a useful subtitle for the bundles of classes
@interface FLEXBundleShortcut : NSObject <FLEXShortcut>
@end
#pragma mark - 
@implementation FLEXBundleShortcut

- (NSString *)titleWith:(id)object {
    return @"Bundle";
}

- (NSString *)subtitleWith:(id)object {
    return [self shortNameForBundlePath:[NSBundle bundleForClass:object].executablePath];
}

- (UIViewController *)viewerWith:(id)object {
    NSBundle *bundle = [NSBundle bundleForClass:object];
    return [FLEXObjectExplorerFactory explorerViewControllerForObject:bundle];
}

- (NSString *)shortNameForBundlePath:(NSString *)imageName {
    NSArray<NSString *> *components = [imageName componentsSeparatedByString:@"/"];
    if (components.count >= 2) {
        return [NSString stringWithFormat:@"%@/%@",
            components[components.count - 2],
            components[components.count - 1]
        ];
    }

    return imageName.lastPathComponent;
}

- (UITableViewCellAccessoryType)accessoryTypeWith:(id)object {
    NSParameterAssert(object != nil);
    return UITableViewCellAccessoryDisclosureIndicator;
}

- (NSString *)customReuseIdentifierWith:(id)object {
    return nil;
}

- (void (^)(UIViewController *))didSelectActionWith:(id)object { 
    return nil;
}

@end

#pragma mark - 
@interface FLEXClassShortcuts ()
@property (nonatomic, readonly) Class cls;
@end

@implementation FLEXClassShortcuts

#pragma mark Internal

- (Class)cls {
    return self.object;
}


#pragma mark Overrides

+ (instancetype)forObject:(Class)cls {
    // These additional rows will appear at the beginning of the shortcuts section.
    // The methods below are written in such a way that they will not interfere
    // with properties/etc being registered alongside these
    return [self forObject:cls additionalRows:@[[FLEXBundleShortcut new], @"Live Instances"]];
}

- (UIViewController *)viewControllerToPushForRow:(NSInteger)row {
    if (row == 1) {
        return [FLEXInstancesTableViewController
            instancesTableViewControllerForClassName:NSStringFromClass(self.cls)
        ];
    }

    return [super viewControllerToPushForRow:row];
}

- (UITableViewCellAccessoryType)accessoryTypeForRow:(NSInteger)row {
    return row == 1 ? UITableViewCellAccessoryDisclosureIndicator : [super accessoryTypeForRow:row];
}

@end
