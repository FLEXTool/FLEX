//
//  FLEXTableViewSection.h
//  FLEX
//
//  Created by Tanner Bennett on 7/11/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// A protocol for arbitrary case-insensitive pattern matching
@protocol FLEXPatternMatching <NSObject>
/// @return YES if the receiver matches the query, case-insensitive
- (BOOL)matches:(NSString *)query;
@end

@interface FLEXTableViewSection<__covariant ObjectType> : NSObject

+ (instancetype)section:(NSInteger)section title:(NSString *)title rows:(NSArray<ObjectType<FLEXPatternMatching>> *)rows;

@property (nonatomic, readonly) NSInteger section;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSArray<ObjectType<FLEXPatternMatching>> *rows;

@property (nonatomic, readonly) NSInteger count;

/// @return A new section containing only rows that match the string,
/// or nil if the section was empty and no rows matched the string.
- (nullable instancetype)newSectionWithRowsMatchingQuery:(NSString *)query;

@end

@interface FLEXTableViewSection<__covariant ObjectType> (Subscripting)
- (ObjectType)objectAtIndexedSubscript:(NSUInteger)idx;
@end

NS_ASSUME_NONNULL_END
