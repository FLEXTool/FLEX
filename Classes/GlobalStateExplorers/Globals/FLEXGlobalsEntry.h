//
//  FLEXGlobalsEntry.h
//  FLEX
//
//  Created by Javier Soto on 7/26/14.
//  Copyright (c) 2014 f. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FLEXTableViewSection.h"
@class FLEXGlobalsTableViewController;

typedef NS_ENUM(NSUInteger, FLEXGlobalsRow) {
    FLEXGlobalsRowProcessInfo,
    FLEXGlobalsRowNetworkHistory,
    FLEXGlobalsRowSystemLog,
    FLEXGlobalsRowLiveObjects,
    FLEXGlobalsRowAddressInspector,
    FLEXGlobalsRowCookies,
    FLEXGlobalsRowSystemLibraries,
    FLEXGlobalsRowAppClasses,
    FLEXGlobalsRowAppKeychainItems,
    FLEXGlobalsRowAppDelegate,
    FLEXGlobalsRowRootViewController,
    FLEXGlobalsRowUserDefaults,
    FLEXGlobalsRowMainBundle,
    FLEXGlobalsRowBrowseBundle,
    FLEXGlobalsRowBrowseContainer,
    FLEXGlobalsRowApplication,
    FLEXGlobalsRowKeyWindow,
    FLEXGlobalsRowMainScreen,
    FLEXGlobalsRowCurrentDevice,
    FLEXGlobalsRowPasteboard,
    FLEXGlobalsRowCount
};

typedef NSString *(^FLEXGlobalsEntryNameFuture)(void);
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
@protocol FLEXGlobalsEntry <NSObject>

+ (NSString *)globalsEntryTitle:(FLEXGlobalsRow)row;

// Must respond to at least one of the below
@optional

+ (UIViewController *)globalsEntryViewController:(FLEXGlobalsRow)row;
+ (FLEXGlobalsTableViewControllerRowAction)globalsEntryRowAction:(FLEXGlobalsRow)row;

@end

@interface FLEXGlobalsEntry : NSObject <FLEXPatternMatching>

@property (nonatomic, readonly) FLEXGlobalsEntryNameFuture entryNameFuture;
@property (nonatomic, readonly) FLEXGlobalsTableViewControllerViewControllerFuture viewControllerFuture;
@property (nonatomic, readonly) FLEXGlobalsTableViewControllerRowAction rowAction;

+ (instancetype)entryWithEntry:(Class<FLEXGlobalsEntry>)entry row:(FLEXGlobalsRow)row;
+ (instancetype)entryWithNameFuture:(FLEXGlobalsEntryNameFuture)nameFuture viewControllerFuture:(FLEXGlobalsTableViewControllerViewControllerFuture)viewControllerFuture;
+ (instancetype)entryWithNameFuture:(FLEXGlobalsEntryNameFuture)nameFuture action:(FLEXGlobalsTableViewControllerRowAction)rowSelectedAction;

@end


@interface NSObject (FLEXGlobalsEntry)

/// @return The result of passing self to +[FLEXGlobalsEntry entryWithEntry:]
/// if the class conforms to FLEXGlobalsEntry, else, nil.
+ (FLEXGlobalsEntry *)flex_concreteGlobalsEntry:(FLEXGlobalsRow)row;

@end
