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
#import "FLEXDatabaseManager.h"
#import "FLEXSQLResult.h"

@interface FLEXSQLiteDatabaseManager : NSObject <FLEXDatabaseManager>

/// Contains the result of the last operation, which may be an error
@property (nonatomic, readonly) FLEXSQLResult *lastResult;
/// Calls into \c sqlite3_last_insert_rowid()
@property (nonatomic, readonly) NSInteger lastRowID;

/// Given a statement like 'SELECT * from @table where @col = @val' and arguments
/// like { @"table": @"Album", @"col": @"year", @"val" @1 } this method will
/// invoke the statement and properly bind the given arguments to the statement.
///
/// You may pass NSStrings, NSData, NSNumbers, or NSNulls as values.
- (FLEXSQLResult *)executeStatement:(NSString *)statement arguments:(NSDictionary<NSString *, id> *)args;

@end
