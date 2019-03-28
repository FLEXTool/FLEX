//
//  FLEXSwiftMirror.m
//  FLEX
//
//  Created by Tanner on 10/28/17.
//  Copyright © 2017 Flipboard. All rights reserved.
//

#import "FLEXSwiftMirror.h"
#import "FLEXSwiftRuntimeUtility.h"
#import "SwiftMetadata.h"
#import <objc/runtime.h>

@interface FLEXSwiftMirror ()
@property (nonatomic, readonly) ClassMetadata *metadata;
@end

@implementation FLEXSwiftMirror

+ (BOOL)isSwiftObjectOrClass:(id)objectOrClass {
    assert(objectOrClass);

    Class cls = objectOrClass;
    if (!object_isClass(objectOrClass)) {
        cls = object_getClass(objectOrClass);
    }

    ClassMetadata *swiftClass = (__bridge ClassMetadata *)(cls);
    return cls == NSClassFromString(@"SwiftObject") || (uintptr_t)swiftClass->rodata & (0x1);
}

+ (instancetype)reflecting:(id)objectOrClass {
    NSAssert([FLEXSwiftRuntimeUtility isSwiftObjectOrClass:objectOrClass],
             @"Attempted to reflect a non-Swift instance: %@", objectOrClass);
    return [[self alloc] initWithTarget:objectOrClass];
}

- (id)initWithTarget:(id)target {
    self = [super init];
    if (self) {
        if (!object_isClass(target)) {
            _classMirror = [FLEXSwiftMirror reflecting:object_getClass(target)];
        }
        _target = target;
    }

    return self;
}

- (NSString *)typeNameForIvarAtOffset:(NSUInteger)offset {

}

@end
