//
//  PTDatabaseManager.m
//  PTDatabaseReader
//
//  Created by Peng Tao on 15/11/23.
//  Copyright © 2015年 Peng Tao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FLEXDatabaseManager.h"

#import "FLEXSQLiteDatabaseParser.h"
#import "FLEXRealmDatabaseParser.h"

@implementation FLEXDatabaseManager {
    NSString *_databasePath;
    id<FLEXDatabaseManagerParser> _parser;
}

- (instancetype)initWithPath:(NSString*)aPath
{
    self = [super init];
    
    if (self) {
        _databasePath = [aPath copy];
        _parser = [self parserForFileAtPath:aPath];
    }
    return self;
}

- (BOOL)open
{
    return [_parser open];
}

- (NSArray *)queryAllTables
{
    return [_parser queryAllTables];
}

- (NSArray *)queryAllColumnsWithTableName:(NSString *)tableName
{
    return [_parser queryAllColumnsWithTableName:tableName];
}

- (NSArray *)queryAllDataWithTableName:(NSString *)tableName
{
    return [_parser queryAllDataWithTableName:tableName];
}

- (id<FLEXDatabaseManagerParser>)parserForFileAtPath:(NSString *)path
{
    NSString *pathExtension = path.pathExtension;
    
    if ([@[@"db", @"sqlite", @"sqlite3"] containsObject:pathExtension]) {
        return [[FLEXSQLiteDatabaseParser alloc] initWithPath:path];
    }
    else if ([pathExtension isEqualToString:@"realm"]) {
        return [[FLEXRealmDatabaseParser alloc] initWithPath:path];
    }
    
    return nil;
}

@end