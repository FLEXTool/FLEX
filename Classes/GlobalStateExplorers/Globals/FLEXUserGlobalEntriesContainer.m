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
#import "FLEXGlobalsViewController.h"

@interface FLEXUserGlobalEntriesContainer ()

@property (nonatomic, readonly) NSMutableArray<FLEXGlobalsEntry *> *entries;

@end

@implementation FLEXUserGlobalEntriesContainer

- (instancetype)init {
    self = [super init];
    if (self) {
        _entries = [NSMutableArray new];
    }
    return self;
}

- (void)registerGlobalEntryWithName:(NSString *)entryName objectFutureBlock:(id (^)(void))objectFutureBlock {
    [self registerGlobalEntryWithName:entryName
                    cellAccessoryType:UITableViewCellAccessoryDisclosureIndicator
                    objectFutureBlock:objectFutureBlock
    ];
}

- (void)registerGlobalEntryWithName:(NSString *)entryName cellAccessoryType:(UITableViewCellAccessoryType)cellAccessoryType objectFutureBlock:(id (^)(void))objectFutureBlock {
    NSParameterAssert(entryName);
    NSParameterAssert(objectFutureBlock);
    NSAssert(NSThread.isMainThread, @"This method must be called from the main thread.");

    entryName = entryName.copy;
    FLEXGlobalsEntry *entry = [FLEXGlobalsEntry entryWithNameFuture:^NSString *{
        return entryName;
    } cellAccessoryType:cellAccessoryType viewControllerFuture:^UIViewController *{
        return [FLEXObjectExplorerFactory explorerViewControllerForObject:objectFutureBlock()];
    }];

    [self.entries addObject:entry];
}

- (void)registerGlobalEntryWithName:(NSString *)entryName viewControllerFutureBlock:(UIViewController * (^)(void))viewControllerFutureBlock {
    [self registerGlobalEntryWithName:entryName
                    cellAccessoryType:UITableViewCellAccessoryDisclosureIndicator
            viewControllerFutureBlock:viewControllerFutureBlock
    ];
}

- (void)registerGlobalEntryWithName:(NSString *)entryName
                  cellAccessoryType:(UITableViewCellAccessoryType)cellAccessoryType
          viewControllerFutureBlock:(UIViewController * (^)(void))viewControllerFutureBlock {
    NSParameterAssert(entryName);
    NSParameterAssert(viewControllerFutureBlock);
    NSAssert(NSThread.isMainThread, @"This method must be called from the main thread.");

    entryName = entryName.copy;
    FLEXGlobalsEntry *entry = [FLEXGlobalsEntry entryWithNameFuture:^NSString *{
        return entryName;
    } cellAccessoryType:cellAccessoryType viewControllerFuture:^UIViewController *{
        UIViewController *viewController = viewControllerFutureBlock();
        NSCAssert(viewController, @"'%@' entry returned nil viewController. viewControllerFutureBlock should never return nil.", entryName);
        return viewController;
    }];

    [self.entries addObject:entry];
}

- (void)registerGlobalEntryWithName:(NSString *)entryName action:(FLEXGlobalsEntryRowAction)rowSelectedAction {
    [self registerGlobalEntryWithName:entryName
                    cellAccessoryType:UITableViewCellAccessoryDisclosureIndicator
                               action:rowSelectedAction
    ];
}

- (void)registerGlobalEntryWithName:(NSString *)entryName
                  cellAccessoryType:(UITableViewCellAccessoryType)cellAccessoryType
                             action:(FLEXGlobalsEntryRowAction)rowSelectedAction {
    NSParameterAssert(entryName);
    NSParameterAssert(rowSelectedAction);
    NSAssert(NSThread.isMainThread, @"This method must be called from the main thread.");

    entryName = entryName.copy;
    FLEXGlobalsEntry *entry = [FLEXGlobalsEntry entryWithNameFuture:^NSString * _Nonnull{
        return entryName;
    } cellAccessoryType:cellAccessoryType action:rowSelectedAction];

    [self.entries addObject:entry];
}

- (void)registerNestedGlobalEntryWithName:(NSString *)entryName handler:(FLEXNestedGlobalEntriesHandler)nestedEntriesHandler {
    [self registerNestedGlobalEntryWithName:entryName
                          cellAccessoryType:UITableViewCellAccessoryDisclosureIndicator
                                    handler:nestedEntriesHandler
    ];
}

- (void)registerNestedGlobalEntryWithName:(NSString *)entryName
                        cellAccessoryType:(UITableViewCellAccessoryType)cellAccessoryType
                                  handler:(FLEXNestedGlobalEntriesHandler)nestedEntriesHandler {
    NSParameterAssert(entryName);
    NSParameterAssert(nestedEntriesHandler);
    NSAssert(NSThread.isMainThread, @"This method must be called from the main thread.");

    entryName = entryName.copy;
    FLEXGlobalsEntry *entry = [FLEXGlobalsEntry entryWithNameFuture:^NSString * _Nonnull{
        return entryName;
    } cellAccessoryType:cellAccessoryType viewControllerFuture:^UIViewController * _Nullable{
        FLEXUserGlobalEntriesContainer *container = [FLEXUserGlobalEntriesContainer new];
        nestedEntriesHandler(container);

        FLEXGlobalsViewController *controller = [FLEXGlobalsViewController new];
        controller.customTitle = entryName;
        controller.customEntries = container.entries;
        controller.showsDefaultEntries = NO;

        return controller;
    }];

    [self.entries addObject:entry];
}

- (void)clearGlobalEntries {
    [self.entries removeAllObjects];
}

@end
