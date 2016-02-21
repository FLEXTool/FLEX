//
//  PTDatabaseManager.m
//  PTDatabaseReader
//
//  Created by Peng Tao on 15/11/23.
//  Copyright © 2015年 Peng Tao. All rights reserved.
//

#import "FLEXSQLiteDatabaseManager.h"
#import <sqlite3.h>


static NSString *const QUERY_TABLENAMES_SQL = @"SELECT name FROM sqlite_master WHERE type='table' ORDER BY name";

@implementation FLEXSQLiteDatabaseManager
{
    sqlite3* _db;
    NSString* _databasePath;
}

- (instancetype)initWithPath:(NSString*)aPath
{
    self = [super init];
    
    if (self) {
        _databasePath = [aPath copy];
    }
    return self;
}

- (BOOL)open {
    if (_db) {
        return YES;
    }
    int err = sqlite3_open([_databasePath UTF8String], &_db);
    if(err != SQLITE_OK) {
        NSLog(@"error opening!: %d", err);
        return NO;
    }
    return YES;
}

- (BOOL)close {
    if (!_db) {
        return YES;
    }
    
    int  rc;
    BOOL retry;
    BOOL triedFinalizingOpenStatements = NO;
    
    do {
        retry   = NO;
        rc      = sqlite3_close(_db);
        if (SQLITE_BUSY == rc || SQLITE_LOCKED == rc) {
            if (!triedFinalizingOpenStatements) {
                triedFinalizingOpenStatements = YES;
                sqlite3_stmt *pStmt;
                while ((pStmt = sqlite3_next_stmt(_db, nil)) !=0) {
                    NSLog(@"Closing leaked statement");
                    sqlite3_finalize(pStmt);
                    retry = YES;
                }
            }
        }
        else if (SQLITE_OK != rc) {
            NSLog(@"error closing!: %d", rc);
        }
    }
    while (retry);
    
    _db = nil;
    return YES;
}


- (NSArray *)queryAllTables
{
    return [self executeQuery:QUERY_TABLENAMES_SQL];
}

- (NSArray *)queryAllColumnsWithTableName:(NSString *)tableName
{
    NSString *sql = [NSString stringWithFormat:@"PRAGMA table_info('%@')",tableName];
    NSArray *resultArray =  [self executeQuery:sql];
    NSMutableArray *array = [NSMutableArray array];
    for (NSDictionary *dict in resultArray) {
        [array addObject:dict[@"name"]];
    }
    return array;
}

- (NSArray *)queryAllDataWithTableName:(NSString *)tableName
{
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@",tableName];
    return [self executeQuery:sql];
}

#pragma mark -
#pragma mark - Private

- (NSArray *)executeQuery:(NSString *)sql
{
    [self open];
    NSMutableArray *resultArray = [NSMutableArray array];
    sqlite3_stmt *pstmt;
    if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &pstmt, 0) == SQLITE_OK) {
        while (sqlite3_step(pstmt) == SQLITE_ROW) {
            NSUInteger num_cols = (NSUInteger)sqlite3_data_count(pstmt);
            if (num_cols > 0) {
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:num_cols];
                
                int columnCount = sqlite3_column_count(pstmt);
                
                int columnIdx = 0;
                for (columnIdx = 0; columnIdx < columnCount; columnIdx++) {
                    
                    NSString *columnName = [NSString stringWithUTF8String:sqlite3_column_name(pstmt, columnIdx)];
                    id objectValue = [self objectForColumnIndex:columnIdx stmt:pstmt];
                    [dict setObject:objectValue forKey:columnName];
                }
                [resultArray addObject:dict];
            }
        }
    }
    [self close];
    return resultArray;
}


- (id)objectForColumnIndex:(int)columnIdx stmt:(sqlite3_stmt*)stmt {
    int columnType = sqlite3_column_type(stmt, columnIdx);
    
    id returnValue = nil;
    
    if (columnType == SQLITE_INTEGER) {
        returnValue =  [NSNumber numberWithLongLong:sqlite3_column_int64(stmt, columnIdx)];
    }
    else if (columnType == SQLITE_FLOAT) {
        returnValue = [NSNumber numberWithDouble:sqlite3_column_double(stmt, columnIdx)];
    }
    else if (columnType == SQLITE_BLOB) {
        returnValue = [self dataForColumnIndex:columnIdx stmt:stmt];
    }
    else {
        //default to a string for everything else
        returnValue = [self stringForColumnIndex:columnIdx stmt:stmt];
    }
    
    if (returnValue == nil) {
        returnValue = [NSNull null];
    }
    
    return returnValue;
}

- (NSString *)stringForColumnIndex:(int)columnIdx stmt:(sqlite3_stmt *)stmt {
    
    if (sqlite3_column_type(stmt, columnIdx) == SQLITE_NULL || (columnIdx < 0)) {
        return nil;
    }
    
    const char *c = (const char *)sqlite3_column_text(stmt, columnIdx);
    
    if (!c) {
        // null row.
        return nil;
    }
    
    return [NSString stringWithUTF8String:c];
}

- (NSData *)dataForColumnIndex:(int)columnIdx stmt:(sqlite3_stmt *)stmt{
    
    if (sqlite3_column_type(stmt, columnIdx) == SQLITE_NULL || (columnIdx < 0)) {
        return nil;
    }
    
    const char *dataBuffer = sqlite3_column_blob(stmt, columnIdx);
    int dataSize = sqlite3_column_bytes(stmt, columnIdx);
    
    if (dataBuffer == NULL) {
        return nil;
    }
    
    return [NSData dataWithBytes:(const void *)dataBuffer length:(NSUInteger)dataSize];
}


@end
