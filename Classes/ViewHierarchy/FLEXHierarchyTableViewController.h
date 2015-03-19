//
//  FLEXHierarchyTableViewController.h
//  Flipboard
//
//  Created by Ryan Olson on 2014-05-01.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FLEXHierarchyTableViewControllerDelegate;

@interface FLEXHierarchyTableViewController : UITableViewController

- (id)initWithViews:(NSArray *)allViews viewsAtTap:(NSArray *)viewsAtTap selectedView:(UIView *)selectedView depths:(NSDictionary *)depthsForViews;

@property (nonatomic, weak) id <FLEXHierarchyTableViewControllerDelegate> delegate;

@end

@protocol FLEXHierarchyTableViewControllerDelegate <NSObject>

- (void)hierarchyViewController:(FLEXHierarchyTableViewController *)hierarchyViewController didFinishWithSelectedView:(UIView *)selectedView;

@end
