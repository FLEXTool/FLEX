//
//  FLEXManager.h
//  Flipboard
//
//  Created by Ryan Olson on 4/4/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FLEXManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, readonly) BOOL isHidden;

- (void)showExplorer;
- (void)hideExplorer;

#pragma mark - Extensions

/// Adds an entry at the bottom of the list of Global State items. Call this method before this view controller is displayed.
/// @param entryName The string to be displayed in the cell.
/// @param objectFutureBlock When you tap on the row, information about the object returned by this block will be displayed.
/// Passing a block that returns an object allows you to display information about an object whose actual pointer may change at runtime (e.g. +currentUser)
/// @note This method must be called from the main thread.
/// The objectFutureBlock will be invoked from the main thread and may return nil.
/// @note The passed block will be copied and retain for the duration of the application, you may want to use __weak references.
- (void)registerGlobalEntryWithName:(NSString *)entryName objectFutureBlock:(id(^)(void))objectFutureBlock;

@end
