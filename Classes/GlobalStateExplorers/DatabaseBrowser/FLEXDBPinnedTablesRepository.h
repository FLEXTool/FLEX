//
//  FLEXDBPinnedTablesRepository.h
//  FLEX
//
//  Created by Hossam Ghareeb on 01/12/2021.
//

#import <Foundation/Foundation.h>

#ifndef FLEXDBPinnedTablesRepository_h
#define FLEXDBPinnedTablesRepository_h

NS_ASSUME_NONNULL_BEGIN

/**
 * Repository to pin/unpin DB tables via table name.
 */
@protocol FLEXDBPinnedTablesRepository <NSObject>

- (void)pinTable:(NSString *)tableName;
- (void)unpinTable:(NSString *)tableName;
- (NSArray<NSString *> *)pinnedTables;

@end

NS_ASSUME_NONNULL_END

#endif /* FLEXDBPinnedTablesRepository_h */
