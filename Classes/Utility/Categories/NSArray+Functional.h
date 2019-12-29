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
- (NSArray *)flex_mapped:(id(^)(T obj, NSUInteger idx))mapFunc;
- (NSArray<T> *)flex_filtered:(BOOL(^)(T obj, NSUInteger idx))filterFunc;
- (void)flex_forEach:(id(^)(T obj, NSUInteger idx))block;

@end
