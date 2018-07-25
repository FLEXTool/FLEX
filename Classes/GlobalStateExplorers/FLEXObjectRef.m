//
//  FLEXObjectRef.m
//  FLEX
//
//  Created by Tanner Bennett on 7/24/18.
//  Copyright (c) 2018 Flipboard. All rights reserved.
//

#import "FLEXObjectRef.h"
#import <objc/runtime.h>

@implementation FLEXObjectRef

+ (instancetype)referencing:(id)object {
    return [[self alloc] initWithObject:object ivarName:nil];
}

+ (instancetype)referencing:(id)object ivar:(NSString *)ivarName {
    return [[self alloc] initWithObject:object ivarName:ivarName];
}

+ (NSArray<FLEXObjectRef *> *)referencingAll:(NSArray *)objects {
    NSMutableArray<FLEXObjectRef *> *refs = [NSMutableArray array];
    for (id obj in objects) {
        [refs addObject:[self referencing:obj]];
    }

    return refs;
}

- (id)initWithObject:(id)object ivarName:(NSString *)ivar {
    self = [super init];
    if (self) {
        _object = object;

        NSString *class = NSStringFromClass(object_getClass(object));
        if (ivar) {
            _reference = [NSString stringWithFormat:@"%@ %@", class, ivar];
        } else {
            _reference = [NSString stringWithFormat:@"%@ %p", class, object];
        }
    }

    return self;
}

@end
