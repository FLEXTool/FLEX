//
//  FLEXKeyboardShortcutManager.h
//  FLEX
//
//  Created by Ryan Olson on 9/19/15.
//  Copyright © 2015 Flipboard. All rights reserved.
//

#import <UIKit/UIKit.h>

#if TARGET_OS_SIMULATOR

@interface FLEXKeyboardShortcutManager : NSObject

+ (instancetype)sharedManager;

- (void)registerSimulatorShortcutWithKey:(NSString *)key modifiers:(UIKeyModifierFlags)modifiers action:(dispatch_block_t)action description:(NSString *)description;
- (NSString *)keyboardShortcutsDescription;

@property (nonatomic, assign, getter=isEnabled) BOOL enabled;

@end

#endif
