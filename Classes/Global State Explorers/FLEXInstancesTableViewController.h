//
//  FLEXInstancesTableViewController.h
//  Flipboard
//
//  Created by Ryan Olson on 5/28/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FLEXInstancesTableViewController : UITableViewController

+ (instancetype)instancesTableViewControllerForClassName:(NSString *)className;
+ (instancetype)instancesTableViewControllerForInstancesReferencingObject:(id)object;

@end
