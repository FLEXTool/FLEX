//
//  FLEXGlobalsTableViewControllerEntry.m
//  FLEX
//
//  Created by Javier Soto on 7/26/14.
//  Copyright (c) 2014 f. All rights reserved.
//

#import "FLEXGlobalsTableViewControllerEntry.h"

@implementation FLEXGlobalsTableViewControllerEntry

+ (instancetype)entryWithEntry:(Class<FLEXGlobalsTableViewControllerEntry>)cls
{
    NSParameterAssert(cls);
    NSParameterAssert(
        [cls respondsToSelector:@selector(globalsEntryViewController)] ||
        [cls respondsToSelector:@selector(globalsEntryRowAction)]
    );

    FLEXGlobalsTableViewControllerEntry *entry = [self new];
    entry->_entryNameFuture = ^{ return [cls globalsEntryTitle]; };

    if ([cls respondsToSelector:@selector(globalsEntryViewController)]) {
        entry->_viewControllerFuture = ^{ return [cls globalsEntryViewController]; };
    } else {
        entry->_rowAction = [cls globalsEntryRowAction];
    }

    return entry;
}

+ (instancetype)entryWithNameFuture:(FLEXGlobalsTableViewControllerEntryNameFuture)nameFuture
               viewControllerFuture:(FLEXGlobalsTableViewControllerViewControllerFuture)viewControllerFuture
{
    NSParameterAssert(nameFuture);
    NSParameterAssert(viewControllerFuture);

    FLEXGlobalsTableViewControllerEntry *entry = [self new];
    entry->_entryNameFuture = [nameFuture copy];
    entry->_viewControllerFuture = [viewControllerFuture copy];

    return entry;
}

+ (instancetype)entryWithNameFuture:(FLEXGlobalsTableViewControllerEntryNameFuture)nameFuture
                             action:(FLEXGlobalsTableViewControllerRowAction)rowSelectedAction
{
    NSParameterAssert(nameFuture);
    NSParameterAssert(rowSelectedAction);

    FLEXGlobalsTableViewControllerEntry *entry = [self new];
    entry->_entryNameFuture = [nameFuture copy];
    entry->_rowAction = [rowSelectedAction copy];

    return entry;
}

@end


@implementation NSObject (FLEXGlobalsTableViewControllerEntry)

+ (FLEXGlobalsTableViewControllerEntry *)flex_concreteGlobalsEntry {
    if ([self conformsToProtocol:@protocol(FLEXGlobalsTableViewControllerEntry)]) {
        return [FLEXGlobalsTableViewControllerEntry entryWithEntry:self];
    }

    return nil;
}

@end
