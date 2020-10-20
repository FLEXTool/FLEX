//
//  FLEXProtocolBuilder.m
//  FLEX
//
//  Derived from MirrorKit.
//  Created by Tanner on 7/4/15.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXProtocolBuilder.h"
#import "FLEXProtocol.h"
#import "FLEXProperty.h"
#import <objc/runtime.h>

#define MutationAssertion(msg) if (self.isRegistered) { \
    [NSException \
        raise:NSInternalInconsistencyException \
        format:msg \
    ]; \
}

@interface FLEXProtocolBuilder ()
@property (nonatomic) Protocol *workingProtocol;
@property (nonatomic) NSString *name;
@end

@implementation FLEXProtocolBuilder

- (id)init {
    [NSException
        raise:NSInternalInconsistencyException
        format:@"Class instance should not be created with -init"
    ];
    return nil;
}

#pragma mark Initializers
+ (instancetype)allocateProtocol:(NSString *)name {
    NSParameterAssert(name);
    return [[self alloc] initWithProtocol:objc_allocateProtocol(name.UTF8String)];
    
}

- (id)initWithProtocol:(Protocol *)protocol {
    NSParameterAssert(protocol);
    
    self = [super init];
    if (self) {
        _workingProtocol = protocol;
        _name = NSStringFromProtocol(self.workingProtocol);
    }
    
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ name=%@, registered=%d>",
            NSStringFromClass(self.class), self.name, self.isRegistered];
}

#pragma mark Building

- (void)addProperty:(FLEXProperty *)property isRequired:(BOOL)isRequired {
    MutationAssertion(@"Properties cannot be added once a protocol has been registered");

    unsigned int count;
    objc_property_attribute_t *attributes = [property copyAttributesList:&count];
    protocol_addProperty(self.workingProtocol, property.name.UTF8String, attributes, count, isRequired, YES);
    free(attributes);
}

- (void)addMethod:(SEL)selector
    typeEncoding:(NSString *)typeEncoding
       isRequired:(BOOL)isRequired
 isInstanceMethod:(BOOL)isInstanceMethod {
    MutationAssertion(@"Methods cannot be added once a protocol has been registered");
    protocol_addMethodDescription(self.workingProtocol, selector, typeEncoding.UTF8String, isRequired, isInstanceMethod);
}

- (void)addProtocol:(Protocol *)protocol {
    MutationAssertion(@"Protocols cannot be added once a protocol has been registered");
    protocol_addProtocol(self.workingProtocol, protocol);
}

- (FLEXProtocol *)registerProtocol {
    MutationAssertion(@"Protocol is already registered");
    
    _isRegistered = YES;
    objc_registerProtocol(self.workingProtocol);
    return [FLEXProtocol protocol:self.workingProtocol];
}

@end
