//
//  FLEXUserGlobalEntriesContainer.m
//  FLEX
//
//  Created by Iulian Onofrei on 2023-02-10.
//  Copyright © 2023 FLEX Team. All rights reserved.
//

#import "FLEXUserGlobalEntriesContainer.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXUserGlobalEntriesContainer+Private.h"

@interface FLEXUserGlobalEntriesContainer ()

@property (nonatomic, readonly) NSMutableArray<FLEXGlobalsEntry *> *userGlobalEntries;

@end

@implementation FLEXUserGlobalEntriesContainer

- (instancetype)init {
    self = [super init];
    if (self) {
        _userGlobalEntries = [NSMutableArray new];
    }
    return self;
}

- (void)registerGlobalEntryWithName:(NSString *)entryName objectFutureBlock:(id (^)(void))objectFutureBlock {
    NSParameterAssert(entryName);
    NSParameterAssert(objectFutureBlock);
    NSAssert(NSThread.isMainThread, @"This method must be called from the main thread.");

    entryName = entryName.copy;
    FLEXGlobalsEntry *entry = [FLEXGlobalsEntry entryWithNameFuture:^NSString *{
        return entryName;
    } viewControllerFuture:^UIViewController *{
        return [FLEXObjectExplorerFactory explorerViewControllerForObject:objectFutureBlock()];
    }];

    [self.userGlobalEntries addObject:entry];
}

- (void)registerGlobalEntryWithName:(NSString *)entryName viewControllerFutureBlock:(UIViewController * (^)(void))viewControllerFutureBlock {
    NSParameterAssert(entryName);
    NSParameterAssert(viewControllerFutureBlock);
    NSAssert(NSThread.isMainThread, @"This method must be called from the main thread.");

    entryName = entryName.copy;
    FLEXGlobalsEntry *entry = [FLEXGlobalsEntry entryWithNameFuture:^NSString *{
        return entryName;
    } viewControllerFuture:^UIViewController *{
        UIViewController *viewController = viewControllerFutureBlock();
        NSCAssert(viewController, @"'%@' entry returned nil viewController. viewControllerFutureBlock should never return nil.", entryName);
        return viewController;
    }];

    [self.userGlobalEntries addObject:entry];
}

- (void)registerGlobalEntryWithName:(NSString *)entryName action:(FLEXGlobalsEntryRowAction)rowSelectedAction {
    NSParameterAssert(entryName);
    NSParameterAssert(rowSelectedAction);
    NSAssert(NSThread.isMainThread, @"This method must be called from the main thread.");

    entryName = entryName.copy;
    FLEXGlobalsEntry *entry = [FLEXGlobalsEntry entryWithNameFuture:^NSString * _Nonnull{
        return entryName;
    } action:rowSelectedAction];

    [self.userGlobalEntries addObject:entry];
}

- (void)clearGlobalEntries {
    [self.userGlobalEntries removeAllObjects];
}

@end
