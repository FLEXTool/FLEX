//
//  FLEXManager+Extensibility.m
//  FLEX
//
//  Created by Tanner on 2/2/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXManager+Extensibility.h"
#import "FLEXKeyboardShortcutManager.h"

NS_ASSUME_NONNULL_BEGIN

@implementation FLEXManager (Extensibility)

#pragma mark - Globals Screen Entries

- (void)registerGlobalEntryWithName:(NSString *)entryName objectFutureBlock:(id (^)(void))objectFutureBlock {
    // Implementation
}

- (void)registerGlobalEntryWithName:(NSString *)entryName
              viewControllerFutureBlock:(UIViewController * (^)(void))viewControllerFutureBlock {
    // Implementation
}

- (void)registerGlobalEntryWithName:(NSString *)entryName action:(FLEXGlobalsEntryRowAction)rowSelectedAction {
    // Implementation
}

- (void)clearGlobalEntries {
    // Implementation
}

#pragma mark - Editing

+ (void)registerFieldNames:(NSArray<NSString *> *)names forTypeEncoding:(NSString *)typeEncoding {
    // Implementation
}

#pragma mark - View Skipping

+ (void)setSkippedViewPredicate:(nullable FLEXViewFilterPredicate)predicate {
    // Implementation
}

+ (nullable FLEXViewFilterPredicate)skippedViewPredicate {
    return nil;
}

#pragma mark - Simulator Shortcuts

- (void)registerSimulatorShortcutWithKey:(NSString *)key
                               modifiers:(UIKeyModifierFlags)modifiers
                                  action:(dispatch_block_t)action
                             description:(NSString *)description {
    // Implementation
}

@end

NS_ASSUME_NONNULL_END