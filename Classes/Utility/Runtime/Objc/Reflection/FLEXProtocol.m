//
//  FLEXProtocol.m
//  FLEX
//
//  Derived from MirrorKit.
//  Created by Tanner on 6/30/15.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXProtocol.h"
#import "FLEXProperty.h"
#import "FLEXRuntimeUtility.h"
#import "NSArray+FLEX.h"
#include <dlfcn.h>

@implementation FLEXProtocol

#pragma mark Initializers

+ (NSArray *)allProtocols {
    unsigned int prcount;
    Protocol *__unsafe_unretained*protocols = objc_copyProtocolList(&prcount);
    
    NSMutableArray *all = [NSMutableArray new];
    for(NSUInteger i = 0; i < prcount; i++)
        [all addObject:[self protocol:protocols[i]]];
    
    free(protocols);
    return all;
}

+ (instancetype)protocol:(Protocol *)protocol {
    return [[self alloc] initWithProtocol:protocol];
}

- (id)initWithProtocol:(Protocol *)protocol {
    NSParameterAssert(protocol);
    
    self = [super init];
    if (self) {
        _objc_protocol = protocol;
        [self examine];
    }
    
    return self;
}

#pragma mark Other

- (NSString *)description {
    return self.name;
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"<%@ name=%@, %lu properties, %lu required methods, %lu optional methods, %lu protocols>",
            NSStringFromClass(self.class), self.name, (unsigned long)self.properties.count,
            (unsigned long)self.requiredMethods.count, (unsigned long)self.optionalMethods.count, (unsigned long)self.protocols.count];
}

- (void)examine {
    _name = @(protocol_getName(self.objc_protocol));
    
    // imagePath
    Dl_info exeInfo;
    if (dladdr((__bridge const void *)(_objc_protocol), &exeInfo)) {
        _imagePath = exeInfo.dli_fname ? @(exeInfo.dli_fname) : nil;
    }
    
    // Conformances and methods //
    
    unsigned int pccount, mdrcount, mdocount;
    struct objc_method_description *objcrMethods, *objcoMethods;
    Protocol *protocol = _objc_protocol;
    Protocol * __unsafe_unretained *protocols = protocol_copyProtocolList(protocol, &pccount);
    
    // Protocols
    _protocols = [NSArray flex_forEachUpTo:pccount map:^id(NSUInteger i) {
        return [FLEXProtocol protocol:protocols[i]];
    }];
    free(protocols);
    
    // Required instance methods
    objcrMethods = protocol_copyMethodDescriptionList(protocol, YES, YES, &mdrcount);
    NSArray *rMethods = [NSArray flex_forEachUpTo:mdrcount map:^id(NSUInteger i) {
        return [FLEXMethodDescription description:objcrMethods[i] instance:YES];
    }];
    free(objcrMethods);
    
    // Required class methods 
    objcrMethods = protocol_copyMethodDescriptionList(protocol, YES, NO, &mdrcount);
    _requiredMethods = [[NSArray flex_forEachUpTo:mdrcount map:^id(NSUInteger i) {
        return [FLEXMethodDescription description:objcrMethods[i] instance:NO];
    }] arrayByAddingObjectsFromArray:rMethods];
    free(objcrMethods);
    
    // Optional instance methods
    objcoMethods = protocol_copyMethodDescriptionList(protocol, NO, YES, &mdocount);
    NSArray *oMethods = [NSArray flex_forEachUpTo:mdocount map:^id(NSUInteger i) {
        return [FLEXMethodDescription description:objcoMethods[i] instance:YES];
    }];
    free(objcoMethods);
    
    // Optional class methods
    objcoMethods = protocol_copyMethodDescriptionList(protocol, NO, NO, &mdocount);
    _optionalMethods = [[NSArray flex_forEachUpTo:mdocount map:^id(NSUInteger i) {
        return [FLEXMethodDescription description:objcoMethods[i] instance:NO];
    }] arrayByAddingObjectsFromArray:oMethods];
    free(objcoMethods);
    
    // Properties is a hassle because they didn't fix the API until iOS 10 //
    
    if (@available(iOS 10.0, *)) {
        unsigned int prrcount, procount;
        Class instance = [NSObject class], meta = objc_getMetaClass("NSObject");
        
        // Required class and instance properties //
        
        // Instance first
        objc_property_t *rProps = protocol_copyPropertyList2(protocol, &prrcount, YES, YES);
        NSArray *rProperties = [NSArray flex_forEachUpTo:prrcount map:^id(NSUInteger i) {
            return [FLEXProperty property:rProps[i] onClass:instance];
        }];
        free(rProps);
        
        // Then class
        rProps = protocol_copyPropertyList2(protocol, &prrcount, NO, YES);
        _requiredProperties = [[NSArray flex_forEachUpTo:prrcount map:^id(NSUInteger i) {
            return [FLEXProperty property:rProps[i] onClass:instance];
        }] arrayByAddingObjectsFromArray:rProperties];
        free(rProps);
        
        // Optional class and instance properties //
        
        // Instance first
        objc_property_t *oProps = protocol_copyPropertyList2(protocol, &procount, YES, YES);
        NSArray *oProperties = [NSArray flex_forEachUpTo:prrcount map:^id(NSUInteger i) {
            return [FLEXProperty property:oProps[i] onClass:meta];
        }];
        free(oProps);
        
        // Then class
        oProps = protocol_copyPropertyList2(protocol, &procount, NO, YES);
        _optionalProperties = [[NSArray flex_forEachUpTo:procount map:^id(NSUInteger i) {
            return [FLEXProperty property:oProps[i] onClass:meta];
        }] arrayByAddingObjectsFromArray:oProperties];
        free(oProps);
        
    } else {
        unsigned int prcount;
        objc_property_t *objcproperties = protocol_copyPropertyList(protocol, &prcount);
        _properties = [NSArray flex_forEachUpTo:prcount map:^id(NSUInteger i) {
            return [FLEXProperty property:objcproperties[i]];
        }];
        
        _requiredProperties = @[];
        _optionalProperties = @[];
        
        free(objcproperties);
    }
}

- (BOOL)conformsTo:(Protocol *)protocol {
    return protocol_conformsToProtocol(self.objc_protocol, protocol);
}

@end

#pragma mark FLEXMethodDescription

@implementation FLEXMethodDescription

- (id)init {
    [NSException
        raise:NSInternalInconsistencyException
        format:@"Class instance should not be created with -init"
    ];
    return nil;
}

+ (instancetype)description:(struct objc_method_description)description {
    return [[self alloc] initWithDescription:description instance:nil];
}

+ (instancetype)description:(struct objc_method_description)description instance:(BOOL)isInstance {
    return [[self alloc] initWithDescription:description instance:@(isInstance)];
}

- (id)initWithDescription:(struct objc_method_description)md instance:(NSNumber *)instance {
    NSParameterAssert(md.name != NULL);
    
    self = [super init];
    if (self) {
        _objc_description = md;
        _selector         = md.name;
        _typeEncoding     = @(md.types);
        _returnType       = (FLEXTypeEncoding)[self.typeEncoding characterAtIndex:0];
        _instance         = instance;
    }
    
    return self;
}

- (NSString *)description {
    return NSStringFromSelector(self.selector);
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"<%@ name=%@, type=%@>",
            NSStringFromClass(self.class), NSStringFromSelector(self.selector), self.typeEncoding];
}

@end
