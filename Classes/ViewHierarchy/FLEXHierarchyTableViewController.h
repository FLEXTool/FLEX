//
//  FLEXHierarchyTableViewController.h
//  Flipboard
//
//  Created by Ryan Olson on 2014-05-01.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FLEXHierarchyTableViewControllerDelegate;
@class FLEXHierarchyItem;

@interface FLEXHierarchyTableViewController : UITableViewController

- (id)initWithItems:(NSArray *)allItems itemsAtTap:(NSArray *)itemsAtTap selectedItem:(FLEXHierarchyItem *)selectedItem depths:(NSDictionary *)depthsForItems;

@property (nonatomic, weak) id <FLEXHierarchyTableViewControllerDelegate> delegate;

@end

@protocol FLEXHierarchyTableViewControllerDelegate <NSObject>

- (void)hierarchyViewController:(FLEXHierarchyTableViewController *)hierarchyViewController didFinishWithSelectedItem:(FLEXHierarchyItem *)selectedItem;

@end
