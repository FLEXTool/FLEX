//
//  PTDatabaseManager.h
//  PTDatabaseReader
//
//  Created by Peng Tao on 15/11/23.
//  Copyright © 2015年 Peng Tao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FLEXDatabaseManager : NSObject


- (instancetype)initWithPath:(NSString*)aPath;

- (BOOL)open;
- (NSArray *)queryAllTables;
- (NSArray *)queryAllColumnsWithTableName:(NSString *)tableName;
- (NSArray *)queryAllDataWithTableName:(NSString *)tableName;

@end
