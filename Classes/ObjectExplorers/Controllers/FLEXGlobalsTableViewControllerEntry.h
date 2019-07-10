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

/// For view controllers to conform to to indicate they support being used
/// in the globals table view controller. These methods help create concrete entries.
///
/// Previously, the concrete entries relied on "futures" for the view controller and title.
/// With this protocol, the conforming class itself can act as a future, since the methods
/// will not be invoked until the title and view controller / row action are needed.
@protocol FLEXGlobalsTableViewControllerEntry <NSObject>

+ (NSString *)globalsEntryTitle;

// Must respond to at least one of the below
@optional

+ (instancetype)globalsEntryViewController;
+ (FLEXGlobalsTableViewControllerRowAction)globalsEntryRowAction;

@end

@interface FLEXGlobalsTableViewControllerEntry : NSObject

@property (nonatomic, readonly) FLEXGlobalsTableViewControllerEntryNameFuture entryNameFuture;
@property (nonatomic, readonly) FLEXGlobalsTableViewControllerViewControllerFuture viewControllerFuture;
@property (nonatomic, readonly) FLEXGlobalsTableViewControllerRowAction rowAction;

+ (instancetype)entryWithEntry:(Class<FLEXGlobalsTableViewControllerEntry>)entry;
+ (instancetype)entryWithNameFuture:(FLEXGlobalsTableViewControllerEntryNameFuture)nameFuture viewControllerFuture:(FLEXGlobalsTableViewControllerViewControllerFuture)viewControllerFuture;
+ (instancetype)entryWithNameFuture:(FLEXGlobalsTableViewControllerEntryNameFuture)nameFuture action:(FLEXGlobalsTableViewControllerRowAction)rowSelectedAction;

@end


@interface NSObject (FLEXGlobalsTableViewControllerEntry)

/// @return The result of passing self to +[FLEXGlobalsTableViewControllerEntry entryWithEntry:]
/// if the class conforms to FLEXGlobalsTableViewControllerEntry, else, nil.
+ (FLEXGlobalsTableViewControllerEntry *)flex_concreteGlobalsEntry;

@end
