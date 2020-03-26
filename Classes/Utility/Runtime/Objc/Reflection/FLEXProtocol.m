//
//  FLEXProtocol.m
//  FLEX
//
//  Derived from MirrorKit.
//  Created by Tanner on 6/30/15.
//  Copyright (c) 2015 Tanner Bennett. All rights reserved.
//

#import "FLEXProtocol.h"
#import "FLEXProperty.h"
#import "FLEXRuntimeUtility.h"
#import "NSAttributedString+FLEX.h"
#import "NSObject+SyntaxHighlighting.h"


@implementation FLEXProtocol

- (id)init {
    [NSException
        raise:NSInternalInconsistencyException
        format:@"Class instance should not be created with -init"
    ];
    return nil;
}

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

- (NSAttributedString *)attributedDescription {
    return self.name.attributedString;
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"<%@ name=%@, %lu properties, %lu required methods, %lu optional methods, %lu protocols>",
            NSStringFromClass(self.class), self.name, (unsigned long)self.properties.count,
            (unsigned long)self.requiredMethods.count, (unsigned long)self.optionalMethods.count, (unsigned long)self.protocols.count];
}

- (NSAttributedString *)attributedDebugDescription {
    return [NSAttributedString stringWithFormat:@"<%@ name=%@, %lu properties, %lu required methods, %lu optional methods, %lu protocols>",
            NSStringFromClass(self.class), self.name, (unsigned long)self.properties.count,
            (unsigned long)self.requiredMethods.count, (unsigned long)self.optionalMethods.count, (unsigned long)self.protocols.count];
}

- (void)examine {
    _name = @(protocol_getName(self.objc_protocol));
    unsigned int prcount, pccount, mdrcount, mdocount;
    
    objc_property_t *objcproperties = protocol_copyPropertyList(self.objc_protocol, &prcount);
    Protocol * __unsafe_unretained *objcprotocols = protocol_copyProtocolList(self.objc_protocol, &pccount);
    struct objc_method_description *objcrmethods = protocol_copyMethodDescriptionList(self.objc_protocol, YES, YES, &mdrcount);
    struct objc_method_description *objcomethods = protocol_copyMethodDescriptionList(self.objc_protocol, NO, YES, &mdocount);
    
    NSMutableArray *properties = [NSMutableArray new];
    for (int i = 0; i < prcount; i++)
        [properties addObject:[FLEXProperty property:objcproperties[i]]];
    _properties = properties;
    
    NSMutableArray *protocols = [NSMutableArray new];
    for (int i = 0; i < pccount; i++)
        [protocols addObject:[FLEXProtocol protocol:objcprotocols[i]]];
    _protocols = protocols;
    
    NSMutableArray *requiredMethods = [NSMutableArray new];
    for (int i = 0; i < mdrcount; i++)
        [requiredMethods addObject:[FLEXMethodDescription description:objcrmethods[i]]];
    _requiredMethods = requiredMethods;
    
    NSMutableArray *optionalMethods = [NSMutableArray new];
    for (int i = 0; i < mdocount; i++)
        [optionalMethods addObject:[FLEXMethodDescription description:objcomethods[i]]];
    _optionalMethods = optionalMethods;
    
    free(objcproperties);
    free(objcprotocols);
    free(objcrmethods);
    free(objcomethods);
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

+ (instancetype)description:(struct objc_method_description)methodDescription {
    return [[self alloc] initWithDescription:methodDescription];
}

- (id)initWithDescription:(struct objc_method_description)md {
    NSParameterAssert(md.name != NULL);
    
    self = [super init];
    if (self) {
        _objc_description = md;
        _selector         = md.name;
        _typeEncoding     = @(md.types);
        _returnType       = (FLEXTypeEncoding)[self.typeEncoding characterAtIndex:0];
    }
    
    return self;
}

- (NSString *)description {
    return NSStringFromSelector(self.selector);
}

- (NSAttributedString *)attributedDescription {
    return NSStringFromSelector(self.selector).attributedString;
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"<%@ name=%@, type=%@>",
            NSStringFromClass(self.class), NSStringFromSelector(self.selector), self.typeEncoding];
}

- (NSAttributedString *)attributedDebugDescription {
    return [NSAttributedString stringWithFormat:@"<%@ name=%@, type=%@>",
            NSStringFromClass(self.class), NSStringFromSelector(self.selector), self.typeEncoding];
}

@end
