//
//  NSArray+Functional.m
//  FLEX
//
//  Created by Tanner Bennett on 9/25/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import "NSArray+Functional.h"

@implementation NSArray (Functional)

- (instancetype)flex_mapped:(id (^)(id, NSUInteger))mapFunc {
    NSMutableArray *map = [NSMutableArray new];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id ret = mapFunc(obj, idx);
        if (ret) {
            [map addObject:ret];
        }
    }];

    return map.copy;
}

- (NSArray *)flex_filtered:(BOOL (^)(id, NSUInteger))filterFunc {
    return [self flex_mapped:^id(id obj, NSUInteger idx) {
        return filterFunc(obj, idx) ? obj : nil;
    }];
}

- (void)flex_forEach:(id (^)(id, NSUInteger))block {
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        block(obj, idx);
    }];
}

@end
