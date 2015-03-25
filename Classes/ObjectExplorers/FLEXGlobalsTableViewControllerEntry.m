//
//  FLEXGlobalsTableViewControllerEntry.m
//  UICatalog
//
//  Created by Javier Soto on 7/26/14.
//  Copyright (c) 2014 f. All rights reserved.
//

#import "FLEXGlobalsTableViewControllerEntry.h"

@implementation FLEXGlobalsTableViewControllerEntry

+ (instancetype)entryWithNameFuture:(FLEXGlobalsTableViewControllerEntryNameFuture)nameFuture viewControllerFuture:(FLEXGlobalsTableViewControllerViewControllerFuture)viewControllerFuture
{
    NSParameterAssert(nameFuture);
    NSParameterAssert(viewControllerFuture);

    FLEXGlobalsTableViewControllerEntry *entry = [[self alloc] init];
    entry->_entryNameFuture = [nameFuture copy];
    entry->_viewControllerFuture = [viewControllerFuture copy];

    return entry;
}

@end