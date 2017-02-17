//
//  FLEXHierarchyTableViewController.h
//  Flipboard
//
//  Created by Ryan Olson on 2014-05-01.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FLEXHierarchyTableViewControllerDelegate;
@class FLEXElement;

@interface FLEXHierarchyTableViewController : UITableViewController

- (id)initWithElements:(NSArray *)allElements elementsAtTap:(NSArray *)elementsAtTap selectedElement:(FLEXElement *)selectedElement depths:(NSDictionary *)depthsForElementObjects;

@property (nonatomic, weak) id <FLEXHierarchyTableViewControllerDelegate> delegate;

@end

@protocol FLEXHierarchyTableViewControllerDelegate <NSObject>

- (void)hierarchyViewController:(FLEXHierarchyTableViewController *)hierarchyViewController didFinishWithSelectedElement:(FLEXElement *)selectedElement;

@end
