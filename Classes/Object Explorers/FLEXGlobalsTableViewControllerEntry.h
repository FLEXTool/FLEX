//
//  FLEXGlobalsTableViewControllerEntry.h
//  UICatalog
//
//  Created by Javier Soto on 7/26/14.
//  Copyright (c) 2014 f. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NSString *(^FLEXGlobalsTableViewControllerEntryNameFuture)(void);
typedef UIViewController *(^FLEXGlobalsTableViewControllerViewControllerFuture)(void);

@interface FLEXGlobalsTableViewControllerEntry : NSObject

@property (nonatomic, readonly, copy) FLEXGlobalsTableViewControllerEntryNameFuture entryNameFuture;
@property (nonatomic, readonly, copy) FLEXGlobalsTableViewControllerViewControllerFuture viewControllerFuture;

+ (instancetype)entryWithNameFuture:(FLEXGlobalsTableViewControllerEntryNameFuture)nameFuture viewControllerFuture:(FLEXGlobalsTableViewControllerViewControllerFuture)viewControllerFuture;

@end
