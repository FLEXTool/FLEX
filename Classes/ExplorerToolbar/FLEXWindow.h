//
//  FLEXWindow.h
//  Flipboard
//
//  Created by Ryan Olson on 4/13/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FLEXWindowEventDelegate;

@interface FLEXWindow : UIWindow

@property (nonatomic, weak) id <FLEXWindowEventDelegate> eventDelegate;

@end

@protocol FLEXWindowEventDelegate <NSObject>

- (BOOL)shouldHandleTouchAtPoint:(CGPoint)pointInWindow;
- (BOOL)canBecomeKeyWindow;

@end
