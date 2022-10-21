//
//  FLEXManager+Extensibility.h
//  FLEX
//
//  Created by Tanner on 2/2/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXManager.h"
#import "FLEXGlobalsEntry.h"

NS_ASSUME_NONNULL_BEGIN

@interface FLEXManager (Extensibility)

#pragma mark - Globals Screen Entries

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
/// @note The passed block will be copied and retain for the duration of the application,
/// you may want to use __weak references as needed.
- (void)registerGlobalEntryWithName:(NSString *)entryName action:(FLEXGlobalsEntryRowAction)rowSelectedAction;

/// Removes all registered global entries.
- (void)clearGlobalEntries;

#pragma mark - Editing

/// Enable displaying ivar names for custom struct types
+ (void)registerFieldNames:(NSArray<NSString *> *)names forTypeEncoding:(NSString *)typeEncoding;

#pragma mark - Simulator Shortcuts

/// Simulator keyboard shortcuts are enabled by default.
/// The shortcuts will not fire when there is an active text field, text view, or other responder
/// accepting key input. You can disable keyboard shortcuts if you have existing keyboard shortcuts
/// that conflict with FLEX, or if you like doing things the hard way ;)
/// Keyboard shortcuts are always disabled (and support is #if'd out) in non-simulator builds
@property (nonatomic) BOOL simulatorShortcutsEnabled;

/// Adds an action to run when the specified key & modifier combination is pressed
/// @param key A single character string matching a key on the keyboard
/// @param modifiers Modifier keys such as shift, command, or alt/option
/// @param action The block to run on the main thread when the key & modifier combination is recognized.
/// @param description Shown the the keyboard shortcut help menu, which is accessed via the '?' key.
/// @note The action block will be retained for the duration of the application. You may want to use weak references.
/// @note FLEX registers several default keyboard shortcuts. Use the '?' key to see a list of shortcuts.
- (void)registerSimulatorShortcutWithKey:(NSString *)key
                               modifiers:(UIKeyModifierFlags)modifiers
                                  action:(dispatch_block_t)action
                             description:(NSString *)description;

@end

NS_ASSUME_NONNULL_END
