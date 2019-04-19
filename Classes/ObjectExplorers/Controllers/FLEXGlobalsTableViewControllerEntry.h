//
//  FLEXGlobalsTableViewControllerEntry.h
//  FLEX
//
//  Created by Javier Soto on 7/26/14.
//  Copyright (c) 2014 f. All rights reserved.
//

#import <UIKit/UIKit.h>
@class FLEXGlobalsTableViewController;

typedef NSString *(^FLEXGlobalsTableViewControllerEntryNameFuture)(void);
/// Simply return a view controller to be pushed on the navigation stack
typedef UIViewController *(^FLEXGlobalsTableViewControllerViewControllerFuture)(void);
/// Do something like present an alert, then use the host
/// view controller to present or push another view controller.
typedef void (^FLEXGlobalsTableViewControllerRowAction)(FLEXGlobalsTableViewController *host);

@interface FLEXGlobalsTableViewControllerEntry : NSObject

@property (nonatomic, readonly, copy) FLEXGlobalsTableViewControllerEntryNameFuture entryNameFuture;
@property (nonatomic, readonly, copy) FLEXGlobalsTableViewControllerViewControllerFuture viewControllerFuture;
@property (nonatomic, readonly, copy) FLEXGlobalsTableViewControllerRowAction rowAction;

+ (instancetype)entryWithNameFuture:(FLEXGlobalsTableViewControllerEntryNameFuture)nameFuture viewControllerFuture:(FLEXGlobalsTableViewControllerViewControllerFuture)viewControllerFuture;
+ (instancetype)entryWithNameFuture:(FLEXGlobalsTableViewControllerEntryNameFuture)nameFuture action:(FLEXGlobalsTableViewControllerRowAction)rowSelectedAction;

@end
