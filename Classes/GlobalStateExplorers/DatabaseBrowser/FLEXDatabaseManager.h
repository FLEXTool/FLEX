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

@protocol FLEXDatabaseManager <NSObject>

@required
- (instancetype)initWithPath:(NSString*)path;

- (BOOL)open;
- (NSArray<NSDictionary<NSString *, id> *> *)queryAllTables;
- (NSArray<NSString *> *)queryAllColumnsWithTableName:(NSString *)tableName;
- (NSArray<NSDictionary<NSString *, id> *> *)queryAllDataWithTableName:(NSString *)tableName;

@end
