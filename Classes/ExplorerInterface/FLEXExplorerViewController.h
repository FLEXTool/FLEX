//
//  FLEXExplorerViewController.h
//  Flipboard
//
//  Created by Ryan Olson on 4/4/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXExplorerToolbar.h"

@class FLEXWindow;
@protocol FLEXExplorerViewControllerDelegate;

/// A view controller that manages the FLEX toolbar.
@interface FLEXExplorerViewController : UIViewController

@property (nonatomic, weak) id <FLEXExplorerViewControllerDelegate> delegate;
@property (nonatomic, readonly) BOOL wantsWindowToBecomeKey;

@property (nonatomic, readonly) FLEXExplorerToolbar *explorerToolbar;

- (BOOL)shouldReceiveTouchAtWindowPoint:(CGPoint)pointInWindowCoordinates;

/// @brief Used to present (or dismiss) a modal view controller ("tool"), typically triggered by pressing a button in the toolbar.
///
/// If a tool is already presented, this method simply dismisses it and calls the completion block.
/// If no tool is presented, @code future() @endcode is presented and the completion block is called.
- (void)toggleToolWithViewControllerProvider:(UINavigationController *(^)(void))future completion:(void(^)(void))completion;

// Keyboard shortcut helpers

- (void)toggleSelectTool;
- (void)toggleMoveTool;
- (void)toggleViewsTool;
- (void)toggleMenuTool;

/// @return YES if the explorer used the key press to perform an action, NO otherwise
- (BOOL)handleDownArrowKeyPressed;
/// @return YES if the explorer used the key press to perform an action, NO otherwise
- (BOOL)handleUpArrowKeyPressed;
/// @return YES if the explorer used the key press to perform an action, NO otherwise
- (BOOL)handleRightArrowKeyPressed;
/// @return YES if the explorer used the key press to perform an action, NO otherwise
- (BOOL)handleLeftArrowKeyPressed;

@end

#pragma mark -
@protocol FLEXExplorerViewControllerDelegate <NSObject>
- (void)explorerViewControllerDidFinish:(FLEXExplorerViewController *)explorerViewController;
@end
