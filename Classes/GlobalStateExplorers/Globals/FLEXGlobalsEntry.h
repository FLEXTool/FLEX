//
//  FLEXGlobalsEntry.h
//  FLEX
//
//  Created by Javier Soto on 7/26/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, FLEXGlobalsRow) {
    FLEXGlobalsRowProcessInfo,
    FLEXGlobalsRowNetworkHistory,
    FLEXGlobalsRowSystemLog,
    FLEXGlobalsRowLiveObjects,
    FLEXGlobalsRowAddressInspector,
    FLEXGlobalsRowCookies,
    FLEXGlobalsRowBrowseRuntime,
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
    FLEXGlobalsRowURLSession,
    FLEXGlobalsRowURLCache,
    FLEXGlobalsRowNotificationCenter,
    FLEXGlobalsRowMenuController,
    FLEXGlobalsRowFileManager,
    FLEXGlobalsRowTimeZone,
    FLEXGlobalsRowLocale,
    FLEXGlobalsRowCalendar,
    FLEXGlobalsRowMainRunLoop,
    FLEXGlobalsRowMainThread,
    FLEXGlobalsRowOperationQueue,
    FLEXGlobalsRowCount
};

typedef NSString * _Nonnull (^FLEXGlobalsEntryNameFuture)(void);
/// Simply return a view controller to be pushed on the navigation stack
typedef UIViewController * _Nullable (^FLEXGlobalsEntryViewControllerFuture)(void);
/// Do something like present an alert, then use the host
/// view controller to present or push another view controller.
typedef void (^FLEXGlobalsEntryRowAction)(__kindof UITableViewController * _Nonnull host);

/// For view controllers to conform to to indicate they support being used
/// in the globals table view controller. These methods help create concrete entries.
///
/// Previously, the concrete entries relied on "futures" for the view controller and title.
/// With this protocol, the conforming class itself can act as a future, since the methods
/// will not be invoked until the title and view controller / row action are needed.
///
/// Entries can implement \c globalsEntryViewController: to unconditionally provide a
/// view controller, or \c globalsEntryRowAction: to conditionally provide one and
/// perform some action (such as present an alert) if no view controller is available,
/// or both if there is a mix of rows where some are guaranteed to work and some are not.
/// Where both are implemented, \c globalsEntryRowAction: takes precedence; if it returns
/// an action for the requested row, that will be used instead of \c globalsEntryViewController:
@protocol FLEXGlobalsEntry <NSObject>

+ (NSString *)globalsEntryTitle:(FLEXGlobalsRow)row;

// Must respond to at least one of the below.
// globalsEntryRowAction: takes precedence if both are implemented.
@optional

+ (nullable UIViewController *)globalsEntryViewController:(FLEXGlobalsRow)row;
+ (nullable FLEXGlobalsEntryRowAction)globalsEntryRowAction:(FLEXGlobalsRow)row;

@end

@interface FLEXGlobalsEntry : NSObject

@property (nonatomic, readonly, nonnull)  FLEXGlobalsEntryNameFuture entryNameFuture;
@property (nonatomic, readonly, nullable) FLEXGlobalsEntryViewControllerFuture viewControllerFuture;
@property (nonatomic, readonly, nullable) FLEXGlobalsEntryRowAction rowAction;

+ (instancetype)entryWithEntry:(Class<FLEXGlobalsEntry>)entry row:(FLEXGlobalsRow)row;

+ (instancetype)entryWithNameFuture:(FLEXGlobalsEntryNameFuture)nameFuture
               viewControllerFuture:(FLEXGlobalsEntryViewControllerFuture)viewControllerFuture;

+ (instancetype)entryWithNameFuture:(FLEXGlobalsEntryNameFuture)nameFuture
                             action:(FLEXGlobalsEntryRowAction)rowSelectedAction;

@end


@interface NSObject (FLEXGlobalsEntry)

/// @return The result of passing self to +[FLEXGlobalsEntry entryWithEntry:]
/// if the class conforms to FLEXGlobalsEntry, else, nil.
+ (nullable FLEXGlobalsEntry *)flex_concreteGlobalsEntry:(FLEXGlobalsRow)row;

@end

NS_ASSUME_NONNULL_END
