//
//  FLEXClassShortcuts.m
//  FLEX
//
//  Created by Tanner Bennett on 11/22/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXClassShortcuts.h"
#import "FLEXShortcut.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXObjectListViewController.h"
#import "NSObject+FLEX_Reflection.h"

@interface FLEXClassShortcuts ()
@property (nonatomic, readonly) Class cls;
@end

@implementation FLEXClassShortcuts

+ (instancetype)forObject:(Class)cls {
    // These additional rows will appear at the beginning of the shortcuts section.
    // The methods below are written in such a way that they will not interfere
    // with properties/etc being registered alongside these
    return [self forObject:cls additionalRows:@[
        [FLEXActionShortcut title:@"Find Live Instances" subtitle:nil
            viewer:^UIViewController *(id obj) {
                return [FLEXObjectListViewController
                    instancesOfClassWithName:NSStringFromClass(obj)
                ];
            }
            accessoryType:^UITableViewCellAccessoryType(id obj) {
                return UITableViewCellAccessoryDisclosureIndicator;
            }
        ],
        [FLEXActionShortcut title:@"List Subclasses" subtitle:nil
            viewer:^UIViewController *(id obj) {
                NSString *name = NSStringFromClass(obj);
                return [FLEXObjectListViewController subclassesOfClassWithName:name];
            }
            accessoryType:^UITableViewCellAccessoryType(id view) {
                return UITableViewCellAccessoryDisclosureIndicator;
            }
        ],
        [FLEXActionShortcut title:@"Explore Bundle for Class"
            subtitle:^NSString *(id obj) {
                return [self shortNameForBundlePath:[NSBundle bundleForClass:obj].executablePath];
            }
            viewer:^UIViewController *(id obj) {
                NSBundle *bundle = [NSBundle bundleForClass:obj];
                return [FLEXObjectExplorerFactory explorerViewControllerForObject:bundle];
            }
            accessoryType:^UITableViewCellAccessoryType(id view) {
                return UITableViewCellAccessoryDisclosureIndicator;
            }
        ],
    ]];
}

+ (NSString *)shortNameForBundlePath:(NSString *)imageName {
    NSArray<NSString *> *components = [imageName componentsSeparatedByString:@"/"];
    if (components.count >= 2) {
        return [NSString stringWithFormat:@"%@/%@",
            components[components.count - 2],
            components[components.count - 1]
        ];
    }

    return imageName.lastPathComponent;
}

@end
