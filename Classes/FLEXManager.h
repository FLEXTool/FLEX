//
//  FLEXManager.h
//  Flipboard
//
//  Created by Ryan Olson on 4/4/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FLEXManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, readonly) BOOL isHidden;

- (void)showExplorer;
- (void)hideExplorer;
- (void)toggleExplorer;

#pragma mark - Network Debugging

/// If this property is set to YES, FLEX will swizzle NSURLConnection*Delegate and NSURLSession*Delegate methods
/// on classes that conform to the protocols. This allows you to view network activity history from the main FLEX menu.
/// Full responses are kept temporarily in a size-limited cache and may be pruned under memory pressure.
@property (nonatomic, assign, getter=isNetworkDebuggingEnabled) BOOL networkDebuggingEnabled;

/// Defaults to 25 MB if never set. Values set here are presisted across launches of the app.
/// The response cache uses an NSCache, so it may purge prior to hitting the limit when the app is under memory pressure.
@property (nonatomic, assign) NSUInteger networkResponseCacheByteLimit;

#pragma mark - Keyboard Shortcuts

/// Simulator keyboard shortcuts are enabled by default.
/// The shortcuts will not fire when there is an active text field, text view, or other responder accepting key input.
/// You can disable keyboard shortcuts if you have existing keyboard shortcuts that conflict with FLEX, or if you like doing things the hard way ;)
/// Keyboard shortcuts are always disabled (and support is compiled out) in non-simulator builds
@property (nonatomic, assign) BOOL simulatorShortcutsEnabled;

/// Adds an action to run when the specified key & modifier combination is pressed
/// @param key A single character string matching a key on the keyboard
/// @param modifiers Modifier keys such as shift, command, or alt/option
/// @param action The block to run on the main thread when the key & modifier combination is recognized.
/// @param description Shown the the keyboard shortcut help menu, which is accessed via the '?' key.
/// @note The action block will be retained for the duration of the application. You may want to use weak references.
/// @note FLEX registers several default keyboard shortcuts. Use the '?' key to see a list of shortcuts.
- (void)registerSimulatorShortcutWithKey:(NSString *)key modifiers:(UIKeyModifierFlags)modifiers action:(dispatch_block_t)action description:(NSString *)description;

#pragma mark - Extensions

/// Adds an entry at the bottom of the list of Global State items. Call this method before this view controller is displayed.
/// @param entryName The string to be displayed in the cell.
/// @param objectFutureBlock When you tap on the row, information about the object returned by this block will be displayed.
/// Passing a block that returns an object allows you to display information about an object whose actual pointer may change at runtime (e.g. +currentUser)
/// @note This method must be called from the main thread.
/// The objectFutureBlock will be invoked from the main thread and may return nil.
/// @note The passed block will be copied and retain for the duration of the application, you may want to use __weak references.
- (void)registerGlobalEntryWithName:(NSString *)entryName objectFutureBlock:(id (^)(void))objectFutureBlock;

/// Adds an entry at the bottom of the list of Global State items. Call this method before this view controller is displayed.
/// @param entryName The string to be displayed in the cell.
/// @param viewControllerFutureBlock When you tap on the row, view controller returned by this block will be pushed on the navigation controller stack.
/// @note This method must be called from the main thread.
/// The viewControllerFutureBlock will be invoked from the main thread and may not return nil.
/// @note The passed block will be copied and retain for the duration of the application, you may want to use __weak references.
- (void)registerGlobalEntryWithName:(NSString *)entryName
          viewControllerFutureBlock:(UIViewController * (^)(void))viewControllerFutureBlock;

@end
