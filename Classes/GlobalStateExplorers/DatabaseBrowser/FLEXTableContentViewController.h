//
//  PTTableContentViewController.h
//  PTDatabaseReader
//
//  Created by Peng Tao on 15/11/23.
//  Copyright © 2015年 Peng Tao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FLEXDatabaseManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface FLEXTableContentViewController : UIViewController

/// Display a table with the given columns, rows, and name.
/// @param databaseManager an optional manager to allow modifying the table.
+ (instancetype)columns:(NSArray<NSString *> *)columnNames
                   rows:(NSArray<NSArray<NSString *> *> *)rowData
                 rowIDs:(nullable NSArray<NSString *> *)rowIds
              tableName:(NSString *)tableName
               database:(nullable id<FLEXDatabaseManager>)databaseManager;

@end

NS_ASSUME_NONNULL_END
