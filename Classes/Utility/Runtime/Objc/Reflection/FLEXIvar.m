//
//  FLEXIvar.m
//  FLEX
//
//  Derived from MirrorKit.
//  Created by Tanner on 6/30/15.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXIvar.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXRuntimeSafety.h"
#import "FLEXTypeEncodingParser.h"
#import "NSString+FLEX.h"
#include "FLEXObjcInternal.h"
#include <dlfcn.h>

@interface FLEXIvar () {
    NSString *_flex_description;
}
@end

@implementation FLEXIvar

#pragma mark Initializers

+ (instancetype)ivar:(Ivar)ivar {
    return [[self alloc] initWithIvar:ivar];
}

+ (instancetype)named:(NSString *)name onClass:(Class)cls {
    Ivar _Nullable ivar = class_getInstanceVariable(cls, name.UTF8String);
    NSAssert(ivar, @"Cannot find ivar with name %@ on class %@", name, cls);
    return [self ivar:ivar];
}

- (id)initWithIvar:(Ivar)ivar {
    NSParameterAssert(ivar);

    self = [super init];
    if (self) {
        _objc_ivar = ivar;
        [self examine];
    }

    return self;
}

#pragma mark Other

- (NSString *)description {
    if (!_flex_description) {
        NSString *readableType = [FLEXRuntimeUtility readableTypeForEncoding:self.typeEncoding];
        _flex_description = [FLEXRuntimeUtility appendName:self.name toType:readableType];
    }

    return _flex_description;
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"<%@ name=%@, encoding=%@, offset=%ld>",
            NSStringFromClass(self.class), self.name, self.typeEncoding, (long)self.offset];
}

- (void)examine {
    _name         = @(ivar_getName(self.objc_ivar) ?: "(nil)");
    _offset       = ivar_getOffset(self.objc_ivar);
    _typeEncoding = @(ivar_getTypeEncoding(self.objc_ivar) ?: "");

    NSString *typeForDetails = _typeEncoding;
    NSString *sizeForDetails = nil;
    if (_typeEncoding.length) {
        _type = (FLEXTypeEncoding)[_typeEncoding characterAtIndex:0];
        FLEXGetSizeAndAlignment(_typeEncoding.UTF8String, &_size, nil);
        sizeForDetails = [@(_size).stringValue stringByAppendingString:@" bytes"];
    } else {
        _type = FLEXTypeEncodingNull;
        typeForDetails = @"no type info";
        sizeForDetails = @"unknown size";
    }

    Dl_info exeInfo;
    if (dladdr(_objc_ivar, &exeInfo)) {
        _imagePath = exeInfo.dli_fname ? @(exeInfo.dli_fname) : nil;
    }

    _details = [NSString stringWithFormat:
        @"%@, offset %@  —  %@",
        sizeForDetails, @(_offset), typeForDetails
    ];
}

- (id)getValue:(id)target {
    id value = nil;
    if (!FLEXIvarIsSafe(_objc_ivar) ||
        _type == FLEXTypeEncodingNull ||
        FLEXPointerIsTaggedPointer(target)) {
        return nil;
    }

#ifdef __arm64__
    // See http://www.sealiesoftware.com/blog/archive/2013/09/24/objc_explain_Non-pointer_isa.html
    if (self.type == FLEXTypeEncodingObjcClass && [self.name isEqualToString:@"isa"]) {
        value = object_getClass(target);
    } else
#endif
    if (self.type == FLEXTypeEncodingObjcObject || self.type == FLEXTypeEncodingObjcClass) {
        value = object_getIvar(target, self.objc_ivar);
    } else {
        void *pointer = (__bridge void *)target + self.offset;
        value = [FLEXRuntimeUtility
            valueForPrimitivePointer:pointer
            objCType:self.typeEncoding.UTF8String
        ];
    }

    return value;
}

- (void)setValue:(id)value onObject:(id)target {
    const char *typeEncodingCString = self.typeEncoding.UTF8String;
    if (self.type == FLEXTypeEncodingObjcObject) {
        object_setIvar(target, self.objc_ivar, value);
    } else if ([value isKindOfClass:[NSValue class]]) {
        // Primitive - unbox the NSValue.
        NSValue *valueValue = (NSValue *)value;

        // Make sure that the box contained the correct type.
        NSAssert(
            strcmp(valueValue.objCType, typeEncodingCString) == 0,
            @"Type encoding mismatch (value: %s; ivar: %s) in setting ivar named: %@ on object: %@",
            valueValue.objCType, typeEncodingCString, self.name, target
        );

        NSUInteger bufferSize = 0;
        if (FLEXGetSizeAndAlignment(typeEncodingCString, &bufferSize, NULL)) {
            void *buffer = calloc(bufferSize, 1);
            [valueValue getValue:buffer];
            void *pointer = (__bridge void *)target + self.offset;
            memcpy(pointer, buffer, bufferSize);
            free(buffer);
        }
    }
}

- (id)getPotentiallyUnboxedValue:(id)target {
    NSString *type = self.typeEncoding;
    if (type.flex_typeIsNonObjcPointer && type.flex_pointeeType != FLEXTypeEncodingVoid) {
        return [self getValue:target];
    }

    return [FLEXRuntimeUtility
        potentiallyUnwrapBoxedPointer:[self getValue:target]
        type:type.UTF8String
    ];
}

@end
