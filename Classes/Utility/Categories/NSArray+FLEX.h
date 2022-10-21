//
//  NSArray+FLEX.h
//  FLEX
//
//  Created by Tanner Bennett on 9/25/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray<T> (Functional)

/// Actually more like flatmap, but it seems like the objc way to allow returning nil to omit objects.
/// So, return nil from the block to omit objects, and return an object to include it in the new array.
/// Unlike flatmap, however, this will not flatten arrays of arrays into a single array.
- (__kindof NSArray *)flex_mapped:(id(^)(T obj, NSUInteger idx))mapFunc;
/// Like flex_mapped, but expects arrays to be returned, and flattens them into one array.
- (__kindof NSArray *)flex_flatmapped:(NSArray *(^)(id, NSUInteger idx))block;
- (instancetype)flex_filtered:(BOOL(^)(T obj, NSUInteger idx))filterFunc;
- (void)flex_forEach:(void(^)(T obj, NSUInteger idx))block;

/// Unlike \c subArrayWithRange: this will not throw an exception if \c maxLength
/// is greater than the size of the array. If the array has one element and
/// \c maxLength is greater than 1, you get an array with 1 element back.
- (instancetype)flex_subArrayUpto:(NSUInteger)maxLength;

+ (instancetype)flex_forEachUpTo:(NSUInteger)bound map:(T(^)(NSUInteger i))block;
+ (instancetype)flex_mapped:(id<NSFastEnumeration>)collection block:(id(^)(T obj, NSUInteger idx))mapFunc;

- (instancetype)flex_sortedUsingSelector:(SEL)selector;

- (T)flex_firstWhere:(BOOL(^)(T obj))meetingCriteria;

@end

@interface NSMutableArray<T> (Functional)

- (void)flex_filter:(BOOL(^)(T obj, NSUInteger idx))filterFunc;

@end
