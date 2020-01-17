//
//  NSArray+Functional.h
//  FLEX
//
//  Created by Tanner Bennett on 9/25/19.
//  Copyright © 2019 Flipboard. All rights reserved.
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

+ (instancetype)flex_forEachUpTo:(NSUInteger)bound map:(T(^)(NSUInteger))block;

- (instancetype)sortedUsingSelector:(SEL)selector;

@end
