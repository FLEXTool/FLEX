//
//  FLEXWindow.h
//  Flipboard
//
//  Created by Ryan Olson on 4/13/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FLEXWindowEventDelegate <NSObject>

- (BOOL)shouldHandleTouchAtPoint:(CGPoint)pointInWindow;
- (BOOL)canBecomeKeyWindow;

@end

#pragma mark -
@interface FLEXWindow : UIWindow

@property (nonatomic, weak) id <FLEXWindowEventDelegate> eventDelegate;

/// Tracked so we can restore the key window after dismissing a modal.
/// We need to become key after modal presentation so we can correctly capture input.
/// If we're just showing the toolbar, we want the main app's window to remain key
/// so that we don't interfere with input, status bar, etc.
@property (nonatomic, readonly) UIWindow *previousKeyWindow;

@end
