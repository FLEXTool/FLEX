//
//  FLEXDBPinnedTablesRepository.h
//  FLEX
//
//  Created by Hossam Ghareeb on 01/12/2021.
//

#import "NSUserDefaults+FLEXDBPinnedTablesRepository.h"

NSString * const key = @"FLEX_DB_PINNED_TABLES_KEY";

@implementation NSUserDefaults (NSUserDefaults_FLEXDBPinnedTablesRepository)

- (void)pinTable:(NSString *)tableName {
    NSMutableOrderedSet<NSString *> *pinnedTables = [self pinnedTableSet]; // set to avoid duplication.
    [pinnedTables insertObject:tableName atIndex:0];
    [self setObject:[pinnedTables array] forKey:key];
}

- (void)unpinTable:(NSString *)tableName {
    NSMutableOrderedSet<NSString *> *pinnedTables = [self pinnedTableSet];
    [pinnedTables removeObject:tableName];
    [self setObject:[pinnedTables array] forKey:key];
}

- (NSArray<NSString *> *)pinnedTables {
    return [self objectForKey:key] ?: @[];
}

// MARK: - Private -

- (NSMutableOrderedSet<NSString *> *)pinnedTableSet {
    return [NSMutableOrderedSet orderedSetWithArray:[self pinnedTables]];
}
@end
