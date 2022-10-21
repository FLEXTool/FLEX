//
//  FLEXMirror.m
//  FLEX
//
//  Derived from MirrorKit.
//  Created by Tanner on 6/29/15.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXMirror.h"
#import "FLEXProperty.h"
#import "FLEXMethod.h"
#import "FLEXIvar.h"
#import "FLEXProtocol.h"
#import "FLEXUtility.h"


#pragma mark FLEXMirror

@implementation FLEXMirror

- (id)init {
    [NSException
        raise:NSInternalInconsistencyException
        format:@"Class instance should not be created with -init"
    ];
    return nil;
}

#pragma mark Initialization
+ (instancetype)reflect:(id)objectOrClass {
    return [[self alloc] initWithSubject:objectOrClass];
}

- (id)initWithSubject:(id)objectOrClass {
    NSParameterAssert(objectOrClass);
    
    self = [super init];
    if (self) {
        _value = objectOrClass;
        [self examine];
    }
    
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %@=%@>",
        NSStringFromClass(self.class),
        self.isClass ? @"metaclass" : @"class",
        self.className
    ];
}

- (void)examine {
    BOOL isClass = object_isClass(self.value);
    Class cls  = isClass ? self.value : object_getClass(self.value);
    Class meta = object_getClass(cls);
    _className = NSStringFromClass(cls);
    _isClass   = isClass;
    
    unsigned int pcount, cpcount, mcount, cmcount, ivcount, pccount;
    Ivar *objcIvars                       = class_copyIvarList(cls, &ivcount);
    Method *objcMethods                   = class_copyMethodList(cls, &mcount);
    Method *objcClsMethods                = class_copyMethodList(meta, &cmcount);
    objc_property_t *objcProperties       = class_copyPropertyList(cls, &pcount);
    objc_property_t *objcClsProperties    = class_copyPropertyList(meta, &cpcount);
    Protocol *__unsafe_unretained *protos = class_copyProtocolList(cls, &pccount);
    
    _ivars = [NSArray flex_forEachUpTo:ivcount map:^id(NSUInteger i) {
        return [FLEXIvar ivar:objcIvars[i]];
    }];
    
    _methods = [NSArray flex_forEachUpTo:mcount map:^id(NSUInteger i) {
        return [FLEXMethod method:objcMethods[i] isInstanceMethod:YES];
    }];
    _classMethods = [NSArray flex_forEachUpTo:cmcount map:^id(NSUInteger i) {
        return [FLEXMethod method:objcClsMethods[i] isInstanceMethod:NO];
    }];
    
    _properties = [NSArray flex_forEachUpTo:pcount map:^id(NSUInteger i) {
        return [FLEXProperty property:objcProperties[i] onClass:cls];
    }];
    _classProperties = [NSArray flex_forEachUpTo:cpcount map:^id(NSUInteger i) {
        return [FLEXProperty property:objcClsProperties[i] onClass:meta];
    }];
    
    _protocols = [NSArray flex_forEachUpTo:pccount map:^id(NSUInteger i) {
        return [FLEXProtocol protocol:protos[i]];
    }];
    
    // Cleanup
    free(objcClsProperties);
    free(objcProperties);
    free(objcClsMethods);
    free(objcMethods);
    free(objcIvars);
    free(protos);
    protos = NULL;
}

#pragma mark Misc

- (FLEXMirror *)superMirror {
    Class cls = _isClass ? _value : object_getClass(_value);
    return [FLEXMirror reflect:class_getSuperclass(cls)];
}

@end


#pragma mark ExtendedMirror

@implementation FLEXMirror (ExtendedMirror)

- (id)filter:(NSArray *)array forName:(NSString *)name {
    NSPredicate *filter = [NSPredicate predicateWithFormat:@"%K = %@", @"name", name];
    return [array filteredArrayUsingPredicate:filter].firstObject;
}

- (FLEXMethod *)methodNamed:(NSString *)name {
    return [self filter:self.methods forName:name];
}

- (FLEXMethod *)classMethodNamed:(NSString *)name {
    return [self filter:self.classMethods forName:name];
}

- (FLEXProperty *)propertyNamed:(NSString *)name {
    return [self filter:self.properties forName:name];
}

- (FLEXProperty *)classPropertyNamed:(NSString *)name {
    return [self filter:self.classProperties forName:name];
}

- (FLEXIvar *)ivarNamed:(NSString *)name {
    return [self filter:self.ivars forName:name];
}

- (FLEXProtocol *)protocolNamed:(NSString *)name {
    return [self filter:self.protocols forName:name];
}

@end
