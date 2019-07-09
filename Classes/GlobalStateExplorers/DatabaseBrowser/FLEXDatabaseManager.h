//
//  PTDatabaseManager.h
//  Derived from:
//
//  FMDatabase.h
//  FMDB( https://github.com/ccgus/fmdb )
//
//  Created by Peng Tao on 15/11/23.
//
//  Licensed to Flying Meat Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Flying Meat Inc. licenses this file to you.

#import <Foundation/Foundation.h>
#import "FLEXSQLResult.h"

@protocol FLEXDatabaseManager <NSObject>

@required

+ (instancetype)managerForDatabase:(NSString *)path;

- (BOOL)open;

/// @return a list of all table names
- (NSArray<NSString *> *)queryAllTables;
- (NSArray<NSString *> *)queryAllColumnsOfTable:(NSString *)tableName;
- (NSArray<NSArray *> *)queryAllDataInTable:(NSString *)tableName;

@optional

- (FLEXSQLResult *)executeStatement:(NSString *)SQLStatement;

@end
