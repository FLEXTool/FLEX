//
//  FLEXObjectListViewController.h
//  Flipboard
//
//  Created by Ryan Olson on 5/28/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXFilteringTableViewController.h"

@interface FLEXObjectListViewController : FLEXFilteringTableViewController

/// This will either return a list of the instances, or take you straight
/// to the explorer itself if there is only one instance.
+ (UIViewController *)instancesOfClassWithName:(NSString *)className;
+ (instancetype)subclassesOfClassWithName:(NSString *)className;
+ (instancetype)objectsWithReferencesToObject:(id)object;

@end
