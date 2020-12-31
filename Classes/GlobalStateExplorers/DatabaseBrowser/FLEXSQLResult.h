//
//  FLEXSQLResult.h
//  FLEX
//
//  Created by Tanner on 3/3/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FLEXSQLResult : NSObject

/// Describes the result of a non-select query, or an error of any kind of query
+ (instancetype)message:(NSString *)message;
/// Describes the result of a known failed execution
+ (instancetype)error:(NSString *)message;

/// @param rowData A list of rows, where each element in the row
/// corresponds to the column given in /c columnNames
+ (instancetype)columns:(NSArray<NSString *> *)columnNames
                rows:(NSArray<NSArray<NSString *> *> *)rowData;

@property (nonatomic, readonly, nullable) NSString *message;

/// A value of YES means this is surely an error,
/// but it still might be an error even with a value of NO
@property (nonatomic, readonly) BOOL isError;

/// A list of column names
@property (nonatomic, readonly, nullable) NSArray<NSString *> *columns;
/// A list of rows, where each element in the row corresponds
/// to the value of the column at the same index in \c columns.
///
/// That is, given a row, looping over the contents of the row and
/// the contents of \c columns will give you key-value pairs of
/// column names to column values for that row.
@property (nonatomic, readonly, nullable) NSArray<NSArray<NSString *> *> *rows;
/// A list of rows where the fields are paired to column names.
///
/// This property is lazily constructed by looping over
/// the rows and columns present in the other two properties.
@property (nonatomic, readonly, nullable) NSArray<NSDictionary<NSString *, id> *> *keyedRows;

@end

NS_ASSUME_NONNULL_END
