//
//  PTDatabaseManager.m
//  PTDatabaseReader
//
//  Created by Peng Tao on 15/11/23.
//  Copyright © 2015年 Peng Tao. All rights reserved.
//

#import "FLEXSQLiteDatabaseManager.h"
#import "FLEXManager.h"
#import "NSArray+Functional.h"
#import <sqlite3.h>

static NSString * const QUERY_TABLENAMES_SQL = @"SELECT name FROM sqlite_master WHERE type='table' ORDER BY name";

@interface FLEXSQLiteDatabaseManager ()
@property (nonatomic, readonly) sqlite3 *db;
@property (nonatomic, copy) NSString *path;
@end

@implementation FLEXSQLiteDatabaseManager

#pragma mark - FLEXDatabaseManager

+ (instancetype)managerForDatabase:(NSString *)path {
    return [[self alloc] initWithPath:path];
}

- (instancetype)initWithPath:(NSString *)path {
    self = [super init];
    if (self) {
        self.path = path;;
    }
    
    return self;
}

- (BOOL)open {
    if (_db) {
        return YES;
    }
    
    int err = sqlite3_open(self.path.UTF8String, &_db);

#if SQLITE_HAS_CODEC
    NSString *defaultSqliteDatabasePassword = FLEXManager.sharedManager.defaultSqliteDatabasePassword;
    if (defaultSqliteDatabasePassword) {
        const char *key = defaultSqliteDatabasePassword.UTF8String;
        sqlite3_key(_db, key, (int)strlen(key));
    }
#endif

    if (err != SQLITE_OK) {
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
    BOOL retry, triedFinalizingOpenStatements = NO;
    
    do {
        retry = NO;
        rc    = sqlite3_close(_db);
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
        } else if (SQLITE_OK != rc) {
            NSLog(@"error closing!: %d", rc);
        }
    } while (retry);
    
    _db = nil;
    return YES;
}

- (NSArray<NSString *> *)queryAllTables {
    return [[self executeQuery:QUERY_TABLENAMES_SQL] flex_mapped:^id(NSArray *table, NSUInteger idx) {
        return table.firstObject;
    }];
}

- (NSArray<NSString *> *)queryAllColumnsWithTableName:(NSString *)tableName {
    NSString *sql = [NSString stringWithFormat:@"PRAGMA table_info('%@')",tableName];
    NSArray<NSDictionary *> *results =  [self executeQueryWithColumns:sql];
    
    return [results flex_mapped:^id(NSDictionary *column, NSUInteger idx) {
        return column[@"name"];
    }];
}

- (NSArray<NSArray *> *)queryAllDataWithTableName:(NSString *)tableName {
    return [self executeQuery:[@"SELECT * FROM "
        stringByAppendingString:tableName
    ]];
}

#pragma mark - Private

/// @return an array of rows, where each row is an array
/// containing the values of each column for that row
- (NSArray<NSArray *> *)executeQuery:(NSString *)sql {
    [self open];
    
    NSMutableArray<NSArray *> *results = [NSMutableArray array];
    
    sqlite3_stmt *pstmt;
    if (sqlite3_prepare_v2(_db, sql.UTF8String, -1, &pstmt, 0) == SQLITE_OK) {
        while (sqlite3_step(pstmt) == SQLITE_ROW) {
            int num_cols = sqlite3_data_count(pstmt);
            if (num_cols > 0) {
                int columnCount = sqlite3_column_count(pstmt);
                
                [results addObject:[NSArray flex_forEachUpTo:columnCount map:^id(NSUInteger i) {
                    return [self objectForColumnIndex:(int)i stmt:pstmt];
                }]];
            }
        }
    }
    
    [self close];
    return results;
}

/// Like \c executeQuery: except that a list of dictionaries are returned,
/// where the keys are column names and the values are the data.
- (NSArray<NSDictionary *> *)executeQueryWithColumns:(NSString *)sql {
    [self open];
    
    NSMutableArray<NSDictionary *> *results = [NSMutableArray array];
    
    sqlite3_stmt *pstmt;
    if (sqlite3_prepare_v2(_db, sql.UTF8String, -1, &pstmt, 0) == SQLITE_OK) {
        while (sqlite3_step(pstmt) == SQLITE_ROW) {
            int num_cols = sqlite3_data_count(pstmt);
            if (num_cols > 0) {
                int columnCount = sqlite3_column_count(pstmt);
                
                
                NSMutableDictionary *rowFields = [NSMutableDictionary new];
                for (int i = 0; i < columnCount; i++) {
                    id value = [self objectForColumnIndex:(int)i stmt:pstmt];
                    rowFields[@(sqlite3_column_name(pstmt, i))] = value;
                }
                
                [results addObject:rowFields];
            }
        }
    }
    
    [self close];
    return results;
}

- (id)objectForColumnIndex:(int)columnIdx stmt:(sqlite3_stmt*)stmt {
    int columnType = sqlite3_column_type(stmt, columnIdx);
    
    switch (columnType) {
        case SQLITE_INTEGER:
            return @(sqlite3_column_int64(stmt, columnIdx)).stringValue;
        case SQLITE_FLOAT:
            return  @(sqlite3_column_double(stmt, columnIdx)).stringValue;
        case SQLITE_BLOB:
            return [NSString stringWithFormat:@"Data (%@ bytes)",
                @([self dataForColumnIndex:columnIdx stmt:stmt].length)
            ];
            
        default:
            // Default to a string for everything else
            return [self stringForColumnIndex:columnIdx stmt:stmt] ?: NSNull.null;
    }
}

- (NSString *)stringForColumnIndex:(int)columnIdx stmt:(sqlite3_stmt *)stmt {
    if (sqlite3_column_type(stmt, columnIdx) == SQLITE_NULL || columnIdx < 0) {
        return nil;
    }
    
    const char *text = (const char *)sqlite3_column_text(stmt, columnIdx);
    return text ? @(text) : nil;
}

- (NSData *)dataForColumnIndex:(int)columnIdx stmt:(sqlite3_stmt *)stmt {
    if (sqlite3_column_type(stmt, columnIdx) == SQLITE_NULL || (columnIdx < 0)) {
        return nil;
    }
    
    const void *blob = sqlite3_column_blob(stmt, columnIdx);
    NSInteger size = (NSInteger)sqlite3_column_bytes(stmt, columnIdx);
    
    return blob ? [NSData dataWithBytes:blob length:size] : nil;
}

@end
