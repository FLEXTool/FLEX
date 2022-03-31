//
//  PTDatabaseManager.m
//  PTDatabaseReader
//
//  Created by Peng Tao on 15/11/23.
//  Copyright © 2015年 Peng Tao. All rights reserved.
//

#import "FLEXSQLiteDatabaseManager.h"
#import "FLEXManager.h"
#import "NSArray+FLEX.h"
#import "FLEXRuntimeConstants.h"
#import <sqlite3.h>

#define kQuery(name, str) static NSString * const QUERY_##name = str

kQuery(TABLENAMES, @"SELECT name FROM sqlite_master WHERE type='table' ORDER BY name");
kQuery(ROWIDS, @"SELECT rowid FROM \"%@\" ORDER BY rowid ASC");

@interface FLEXSQLiteDatabaseManager ()
@property (nonatomic) sqlite3 *db;
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
        self.path = path;
    }
    
    return self;
}

- (void)dealloc {
    [self close];
}

- (BOOL)open {
    if (self.db) {
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
        return [self storeErrorForLastTask:@"Open"];
    }
    
    return YES;
}
    
- (BOOL)close {
    if (!self.db) {
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
            [self storeErrorForLastTask:@"Close"];
            self.db = nil;
            return NO;
        }
    } while (retry);
    
    self.db = nil;
    return YES;
}

- (NSInteger)lastRowID {
    return (NSInteger)sqlite3_last_insert_rowid(self.db);
}

- (NSArray<NSString *> *)queryAllTables {
    return [[self executeStatement:QUERY_TABLENAMES].rows flex_mapped:^id(NSArray *table, NSUInteger idx) {
        return table.firstObject;
    }] ?: @[];
}

- (NSArray<NSString *> *)queryAllColumnsOfTable:(NSString *)tableName {
    NSString *sql = [NSString stringWithFormat:@"PRAGMA table_info('%@')",tableName];
    FLEXSQLResult *results = [self executeStatement:sql];
    
    // https://github.com/FLEXTool/FLEX/issues/554
    if (!results.keyedRows.count) {
        sql = [NSString stringWithFormat:@"SELECT * FROM pragma_table_info('%@')", tableName];
        results = [self executeStatement:sql];
        
        // Fallback to empty query
        if (!results.keyedRows.count) {
            sql = [NSString stringWithFormat:@"SELECT * FROM \"%@\" where 0=1", tableName];
            return [self executeStatement:sql].columns ?: @[];
        }
    }
    
    return [results.keyedRows flex_mapped:^id(NSDictionary *column, NSUInteger idx) {
        return column[@"name"];
    }] ?: @[];
}

- (NSArray<NSArray *> *)queryAllDataInTable:(NSString *)tableName {
    NSString *command = [NSString stringWithFormat:@"SELECT * FROM \"%@\"", tableName];
    return [self executeStatement:command].rows ?: @[];
}

- (NSArray<NSString *> *)queryRowIDsInTable:(NSString *)tableName {
    NSString *command = [NSString stringWithFormat:QUERY_ROWIDS, tableName];
    NSArray<NSArray<NSString *> *> *data = [self executeStatement:command].rows ?: @[];
    
    return [data flex_mapped:^id(NSArray<NSString *> *obj, NSUInteger idx) {
        return obj.firstObject;
    }];
}

- (FLEXSQLResult *)executeStatement:(NSString *)sql {
    return [self executeStatement:sql arguments:nil];
}

- (FLEXSQLResult *)executeStatement:(NSString *)sql arguments:(NSDictionary *)args {
    [self open];
    
    FLEXSQLResult *result = nil;
    
    sqlite3_stmt *pstmt;
    int status;
    if ((status = sqlite3_prepare_v2(_db, sql.UTF8String, -1, &pstmt, 0)) == SQLITE_OK) {
        NSMutableArray<NSArray *> *rows = [NSMutableArray new];
        
        // Bind parameters, if any
        if (![self bindParameters:args toStatement:pstmt]) {
            return self.lastResult;
        }
        
        // Grab columns (columnCount will be 0 for insert/update/delete) 
        int columnCount = sqlite3_column_count(pstmt);
        NSArray<NSString *> *columns = [NSArray flex_forEachUpTo:columnCount map:^id(NSUInteger i) {
            return @(sqlite3_column_name(pstmt, (int)i));
        }];
        
        // Execute statement
        while ((status = sqlite3_step(pstmt)) == SQLITE_ROW) {
            // Grab rows if this is a selection query
            int dataCount = sqlite3_data_count(pstmt);
            if (dataCount > 0) {
                [rows addObject:[NSArray flex_forEachUpTo:columnCount map:^id(NSUInteger i) {
                    return [self objectForColumnIndex:(int)i stmt:pstmt];
                }]];
            }
        }
        
        if (status == SQLITE_DONE) {
            // columnCount will be 0 for insert/update/delete
            if (rows.count || columnCount > 0) {
                // We executed a SELECT query
                result = _lastResult = [FLEXSQLResult columns:columns rows:rows];
            } else {
                // We executed a query like INSERT, UDPATE, or DELETE
                int rowsAffected = sqlite3_changes(_db);
                NSString *message = [NSString stringWithFormat:@"%d row(s) affected", rowsAffected];
                result = _lastResult = [FLEXSQLResult message:message];
            }
        } else {
            // An error occured executing the query
            result = _lastResult = [self errorResult:@"Execution"];
        }
    } else {
        // An error occurred creating the prepared statement
        result = _lastResult = [self errorResult:@"Prepared statement"];
    }
    
    sqlite3_finalize(pstmt);
    return result;
}


#pragma mark - Private

/// @return YES on success, NO if an error was encountered and stored in \c lastResult
- (BOOL)bindParameters:(NSDictionary *)args toStatement:(sqlite3_stmt *)pstmt {
    for (NSString *param in args.allKeys) {
        int status = SQLITE_OK, idx = sqlite3_bind_parameter_index(pstmt, param.UTF8String);
        id value = args[param];
        
        if (idx == 0) {
            // No parameter matching that arg
            @throw NSInternalInconsistencyException;
        }
        
        // Null
        if ([value isKindOfClass:[NSNull class]]) {
            status = sqlite3_bind_null(pstmt, idx);
        }
        // String params
        else if ([value isKindOfClass:[NSString class]]) {
            const char *str = [value UTF8String];
            status = sqlite3_bind_text(pstmt, idx, str, (int)strlen(str), SQLITE_TRANSIENT);
        }
        // Data params
        else if ([value isKindOfClass:[NSData class]]) {
            const void *blob = [value bytes];
            status = sqlite3_bind_blob64(pstmt, idx, blob, [value length], SQLITE_TRANSIENT);
        }
        // Primitive params
        else if ([value isKindOfClass:[NSNumber class]]) {
            FLEXTypeEncoding type = [value objCType][0];
            switch (type) {
                case FLEXTypeEncodingCBool:
                case FLEXTypeEncodingChar:
                case FLEXTypeEncodingUnsignedChar:
                case FLEXTypeEncodingShort:
                case FLEXTypeEncodingUnsignedShort:
                case FLEXTypeEncodingInt:
                case FLEXTypeEncodingUnsignedInt:
                case FLEXTypeEncodingLong:
                case FLEXTypeEncodingUnsignedLong:
                case FLEXTypeEncodingLongLong:
                case FLEXTypeEncodingUnsignedLongLong:
                    status = sqlite3_bind_int64(pstmt, idx, (sqlite3_int64)[value longValue]);
                    break;
                
                case FLEXTypeEncodingFloat:
                case FLEXTypeEncodingDouble:
                    status = sqlite3_bind_double(pstmt, idx, [value doubleValue]);
                    break;
                    
                default:
                    @throw NSInternalInconsistencyException;
                    break;
            }
        }
        // Unsupported type
        else {
            @throw NSInternalInconsistencyException;
        }
        
        if (status != SQLITE_OK) {
            return [self storeErrorForLastTask:
                [NSString stringWithFormat:@"Binding param named '%@'", param]
            ];
        }
    }
    
    return YES;
}

- (BOOL)storeErrorForLastTask:(NSString *)action {
    _lastResult = [self errorResult:action];
    return NO;
}

- (FLEXSQLResult *)errorResult:(NSString *)description {
    const char *error = sqlite3_errmsg(_db);
    NSString *message = error ? @(error) : [NSString
        stringWithFormat:@"(%@: empty error)", description
    ];
    
    return [FLEXSQLResult error:message];
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
