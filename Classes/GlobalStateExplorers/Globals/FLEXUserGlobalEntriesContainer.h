//
//  FLEXUserGlobalEntriesContainer.h
//  FLEX
//
//  Created by Iulian Onofrei on 2023-02-10.
//  Copyright © 2023 FLEX Team. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FLEXGlobalsEntry.h"

NS_ASSUME_NONNULL_BEGIN

@interface FLEXUserGlobalEntriesContainer : NSObject

/// Adds an entry at the top of the list of Global State items.
/// Call this method before this view controller is displayed.
/// @param entryName The string to be displayed in the cell.
/// @param objectFutureBlock When you tap on the row, information about the object returned
/// by this block will be displayed. Passing a block that returns an object allows you to display
/// information about an object whose actual pointer may change at runtime (e.g. +currentUser)
/// @note This method must be called from the main thread.
/// The objectFutureBlock will be invoked from the main thread and may return nil.
/// @note The passed block will be copied and retain for the duration of the application,
/// you may want to use __weak references.
- (void)registerGlobalEntryWithName:(NSString *)entryName objectFutureBlock:(id (^)(void))objectFutureBlock;

/// Adds an entry at the top of the list of Global State items.
/// Call this method before this view controller is displayed.
/// @param entryName The string to be displayed in the cell.
/// @param viewControllerFutureBlock When you tap on the row, view controller returned
/// by this block will be pushed on the navigation controller stack.
/// @note This method must be called from the main thread.
/// The viewControllerFutureBlock will be invoked from the main thread and may not return nil.
/// @note The passed block will be copied and retain for the duration of the application,
/// you may want to use __weak references as needed.
- (void)registerGlobalEntryWithName:(NSString *)entryName
          viewControllerFutureBlock:(UIViewController * (^)(void))viewControllerFutureBlock;

/// Adds an entry at the top of the list of Global State items.
/// @param entryName The string to be displayed in the cell.
/// @param rowSelectedAction When you tap on the row, this block will be invoked
/// with the host table view view controller. Use it to deselect the row or present an alert.
/// @note This method must be called from the main thread.
/// The rowSelectedAction will be invoked from the main thread.
/// @note The passed block will be copied and retained for the duration of the application,
/// you may want to use __weak references as needed.
- (void)registerGlobalEntryWithName:(NSString *)entryName action:(FLEXGlobalsEntryRowAction)rowSelectedAction;

/// Adds an entry at the top of the list of Global State items.
/// @param entryName The string to be displayed in the cell.
/// @param nestedEntriesHandler When you tap on the row, this block will be invoked
/// with the container object. Use it to register nested entries.
/// @note This method must be called from the main thread.
/// The nestedEntriesHandler will be invoked from the main thread.
/// @note The passed block will be copied and retained for the duration of the application,
/// you may want to use __weak references as needed.
- (void)registerNestedGlobalEntryWithName:(NSString *)entryName handler:(FLEXNestedGlobalEntriesHandler)nestedEntriesHandler;

/// Removes all registered global entries.
- (void)clearGlobalEntries;

@end

NS_ASSUME_NONNULL_END
