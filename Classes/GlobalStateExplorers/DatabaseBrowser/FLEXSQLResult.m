//
//  FLEXSQLResult.m
//  FLEX
//
//  Created by Tanner on 3/3/20.
//  Copyright © 2020 Flipboard. All rights reserved.
//

#import "FLEXSQLResult.h"
#import "NSArray+FLEX.h"

@implementation FLEXSQLResult
@synthesize keyedRows = _keyedRows;

+ (instancetype)message:(NSString *)message {
    return [[self alloc] initWithmessage:message columns:nil rows:nil];
}

+ (instancetype)error:(NSString *)message {
    FLEXSQLResult *result = [self message:message];
    result->_isError = YES;
    return result;
}

+ (instancetype)columns:(NSArray<NSString *> *)columnNames rows:(NSArray<NSArray<NSString *> *> *)rowData {
    return [[self alloc] initWithmessage:nil columns:columnNames rows:rowData];
}

- (id)initWithmessage:(NSString *)message columns:(NSArray *)columns rows:(NSArray<NSArray *> *)rows {
    NSParameterAssert(message || (columns && rows));
    NSParameterAssert(columns.count == rows.firstObject.count);
    
    self = [super init];
    if (self) {
        _message = message;
        _columns = columns;
        _rows = rows;
    }
    
    return self;
}

- (NSArray<NSDictionary<NSString *,id> *> *)keyedRows {
    if (!_keyedRows) {
        _keyedRows = [self.rows flex_mapped:^id(NSArray<NSString *> *row, NSUInteger idx) {
            return [NSDictionary dictionaryWithObjects:row forKeys:self.columns];
        }];
    }
    
    return _keyedRows;
}

@end
