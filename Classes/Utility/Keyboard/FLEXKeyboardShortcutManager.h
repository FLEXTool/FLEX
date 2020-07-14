//
//  FLEXKeyboardShortcutManager.h
//  FLEX
//
//  Created by Ryan Olson on 9/19/15.
//  Copyright © 2015 Flipboard. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FLEXKeyboardShortcutManager : NSObject

@property (nonatomic, readonly, class) FLEXKeyboardShortcutManager *sharedManager;

- (void)registerSimulatorShortcutWithKey:(NSString *)key
                               modifiers:(UIKeyModifierFlags)modifiers
                                  action:(dispatch_block_t)action
                             description:(NSString *)description;

@property (nonatomic, getter=isEnabled) BOOL enabled;
@property (nonatomic, readonly) NSString *keyboardShortcutsDescription;

@end
