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

/// If this property is set to YES, FLEX will swizzle NSURLConnection*Delegate and NSURLSession*Delegate methods
/// on classes that conform to the protocols. This allows you to view network activity history from the main FLEX menu.
/// Full responses are kept temporarily in a size limited cache and may be pruged under memory pressure.
@property (nonatomic, assign, getter=isNetworkDebuggingEnabled) BOOL networkDebuggingEnabled;

/// Defaults to 50 MB if never set. Values set here are presisted across launches of the app.
/// The response cache uses an NSCache, so it may purge prior to hitting the limit when the app is under memory pressure.
@property (nonatomic, assign) NSUInteger networkResponseCacheByteLimit;

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
