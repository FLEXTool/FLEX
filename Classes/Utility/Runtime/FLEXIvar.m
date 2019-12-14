//
//  FLEXIvar.m
//  FLEX
//
//  Derived from MirrorKit.
//  Created by Tanner on 6/30/15.
//  Copyright (c) 2015 Tanner Bennett. All rights reserved.
//

#import "FLEXIvar.h"
#import "FLEXRuntimeUtility.h"

@interface FLEXIvar () {
    NSString *_flex_description;
}
@end

@implementation FLEXIvar

#pragma mark Initializers

- (id)init {
    [NSException
        raise:NSInternalInconsistencyException
        format:@"Class instance should not be created with -init"
    ];
    return nil;
}

+ (instancetype)ivar:(Ivar)ivar {
    return [[self alloc] initWithIvar:ivar];
}

+ (instancetype)named:(NSString *)name onClass:(Class)cls {
    Ivar ivar = class_getInstanceVariable(cls, name.UTF8String);
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
    _name         = @(ivar_getName(self.objc_ivar));
    _typeEncoding = @(ivar_getTypeEncoding(self.objc_ivar));
    _type         = (FLEXTypeEncoding)[_typeEncoding characterAtIndex:0];
    _offset       = ivar_getOffset(self.objc_ivar);
}

- (id)getValue:(id)target {
    return [FLEXRuntimeUtility valueForIvar:self.objc_ivar onObject:target];
}

- (id)getPotentiallyUnboxedValue:(id)target {
    return [FLEXRuntimeUtility
        potentiallyUnwrapBoxedPointer:[self getValue:target]
        type:self.typeEncoding.UTF8String
    ];
}

@end
