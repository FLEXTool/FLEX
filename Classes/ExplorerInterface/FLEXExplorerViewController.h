//
//  FLEXExplorerViewController.h
//  Flipboard
//
//  Created by Ryan Olson on 4/4/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FLEXExplorerViewControllerDelegate;

/// A view controller that manages the FLEX toolbar.
@interface FLEXExplorerViewController : UIViewController

@property (nonatomic, weak) id <FLEXExplorerViewControllerDelegate> delegate;

- (BOOL)shouldReceiveTouchAtWindowPoint:(CGPoint)pointInWindowCoordinates;
- (BOOL)wantsWindowToBecomeKey;

/// @brief Used to present (or dismiss) a modal view controller ("tool"), typically triggered by pressing a button in the toolbar.
///
/// If a tool is already presented, this method simply dismisses it and calls the completion block.
/// If no tool is presented, @code future() @endcode is presented and the completion block is called.
- (void)toggleToolWithViewControllerProvider:(UIViewController *(^)(void))future completion:(void(^)(void))completion;

// Keyboard shortcut helpers

- (void)toggleSelectTool;
- (void)toggleMoveTool;
- (void)toggleViewsTool;
- (void)toggleMenuTool;
- (void)handleDownArrowKeyPressed;
- (void)handleUpArrowKeyPressed;
- (void)handleRightArrowKeyPressed;
- (void)handleLeftArrowKeyPressed;

@end

@protocol FLEXExplorerViewControllerDelegate <NSObject>

- (void)explorerViewControllerDidFinish:(FLEXExplorerViewController *)explorerViewController;

@end
