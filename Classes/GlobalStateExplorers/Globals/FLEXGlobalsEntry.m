//
//  FLEXGlobalsEntry.m
//  FLEX
//
//  Created by Javier Soto on 7/26/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXGlobalsEntry.h"

@implementation FLEXGlobalsEntry

+ (instancetype)entryWithEntry:(Class<FLEXGlobalsEntry>)cls
             cellAccessoryType:(UITableViewCellAccessoryType)cellAccessoryType
                           row:(FLEXGlobalsRow)row {
    BOOL providesVCs = [cls respondsToSelector:@selector(globalsEntryViewController:)];
    BOOL providesActions = [cls respondsToSelector:@selector(globalsEntryRowAction:)];
    NSParameterAssert(cls);
    NSParameterAssert(providesVCs || providesActions);

    FLEXGlobalsEntry *entry = [self new];
    entry->_entryNameFuture = ^{ return [cls globalsEntryTitle:row]; };
    entry->_cellAccessoryType = cellAccessoryType;

    if (providesVCs) {
        id action = providesActions ? [cls globalsEntryRowAction:row] : nil;
        if (action) {
            entry->_rowAction = action;
        } else {
            entry->_viewControllerFuture = ^{ return [cls globalsEntryViewController:row]; };
        }
    } else {
        entry->_rowAction = [cls globalsEntryRowAction:row];
    }

    return entry;
}

+ (instancetype)entryWithNameFuture:(FLEXGlobalsEntryNameFuture)nameFuture
                  cellAccessoryType:(UITableViewCellAccessoryType)cellAccessoryType
               viewControllerFuture:(FLEXGlobalsEntryViewControllerFuture)viewControllerFuture {
    NSParameterAssert(nameFuture);
    NSParameterAssert(viewControllerFuture);

    FLEXGlobalsEntry *entry = [self new];
    entry->_entryNameFuture = [nameFuture copy];
    entry->_cellAccessoryType = cellAccessoryType;
    entry->_viewControllerFuture = [viewControllerFuture copy];

    return entry;
}

+ (instancetype)entryWithNameFuture:(FLEXGlobalsEntryNameFuture)nameFuture
                  cellAccessoryType:(UITableViewCellAccessoryType)cellAccessoryType
                             action:(FLEXGlobalsEntryRowAction)rowSelectedAction {
    NSParameterAssert(nameFuture);
    NSParameterAssert(rowSelectedAction);

    FLEXGlobalsEntry *entry = [self new];
    entry->_entryNameFuture = [nameFuture copy];
    entry->_cellAccessoryType = cellAccessoryType;
    entry->_rowAction = [rowSelectedAction copy];

    return entry;
}

@end

@interface FLEXGlobalsEntry (Debugging)
@property (nonatomic, readonly) NSString *name;
@end

@implementation FLEXGlobalsEntry (Debugging)

- (NSString *)name {
    return self.entryNameFuture();
}

@end

#pragma mark - flex_concreteGlobalsEntry

@implementation NSObject (FLEXGlobalsEntry)

+ (FLEXGlobalsEntry *)flex_concreteGlobalsEntry:(FLEXGlobalsRow)row {
    if ([self conformsToProtocol:@protocol(FLEXGlobalsEntry)]) {
        return [FLEXGlobalsEntry entryWithEntry:self
                              cellAccessoryType:UITableViewCellAccessoryDisclosureIndicator
                                            row:row
        ];
    }

    return nil;
}

@end
