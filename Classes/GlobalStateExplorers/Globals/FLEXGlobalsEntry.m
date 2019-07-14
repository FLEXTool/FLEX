//
//  FLEXGlobalsEntry.m
//  FLEX
//
//  Created by Javier Soto on 7/26/14.
//  Copyright (c) 2014 f. All rights reserved.
//

#import "FLEXGlobalsEntry.h"

@implementation FLEXGlobalsEntry

+ (instancetype)entryWithEntry:(Class<FLEXGlobalsEntry>)cls row:(FLEXGlobalsRow)row
{
    NSParameterAssert(cls);
    NSParameterAssert(
        [cls respondsToSelector:@selector(globalsEntryViewController:)] ||
        [cls respondsToSelector:@selector(globalsEntryRowAction:)]
    );

    FLEXGlobalsEntry *entry = [self new];
    entry->_entryNameFuture = ^{ return [cls globalsEntryTitle:row]; };

    if ([cls respondsToSelector:@selector(globalsEntryViewController:)]) {
        entry->_viewControllerFuture = ^{ return [cls globalsEntryViewController:row]; };
    } else {
        entry->_rowAction = [cls globalsEntryRowAction:row];
    }

    return entry;
}

+ (instancetype)entryWithNameFuture:(FLEXGlobalsEntryNameFuture)nameFuture
               viewControllerFuture:(FLEXGlobalsTableViewControllerViewControllerFuture)viewControllerFuture
{
    NSParameterAssert(nameFuture);
    NSParameterAssert(viewControllerFuture);

    FLEXGlobalsEntry *entry = [self new];
    entry->_entryNameFuture = [nameFuture copy];
    entry->_viewControllerFuture = [viewControllerFuture copy];

    return entry;
}

+ (instancetype)entryWithNameFuture:(FLEXGlobalsEntryNameFuture)nameFuture
                             action:(FLEXGlobalsTableViewControllerRowAction)rowSelectedAction
{
    NSParameterAssert(nameFuture);
    NSParameterAssert(rowSelectedAction);

    FLEXGlobalsEntry *entry = [self new];
    entry->_entryNameFuture = [nameFuture copy];
    entry->_rowAction = [rowSelectedAction copy];

    return entry;
}

#pragma mark FLEXPatternMatching

- (BOOL)matches:(NSString *)query
{
    return [self.entryNameFuture() localizedCaseInsensitiveContainsString:query];
}

@end

#pragma mark - flex_concreteGlobalsEntry

@implementation NSObject (FLEXGlobalsEntry)

+ (FLEXGlobalsEntry *)flex_concreteGlobalsEntry:(FLEXGlobalsRow)row {
    if ([self conformsToProtocol:@protocol(FLEXGlobalsEntry)]) {
        return [FLEXGlobalsEntry entryWithEntry:self row:row];
    }

    return nil;
}

@end
