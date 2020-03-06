//
//  FLEXObjectListViewController.h
//  Flipboard
//
//  Created by Ryan Olson on 5/28/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXTableViewController.h"

@interface FLEXObjectListViewController : FLEXTableViewController

+ (instancetype)instancesOfClassWithName:(NSString *)className;
+ (instancetype)subclassesOfClassWithName:(NSString *)className;
+ (instancetype)objectsWithReferencesToObject:(id)object;

@end
