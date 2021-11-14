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
    NSString *type = self.isClass ? @"metaclass" : @"class";
    return [NSString
        stringWithFormat:@"<%@ %@=%@, %lu properties, %lu ivars, %lu methods, %lu protocols>",
        NSStringFromClass(self.class),
        type,
        self.className,
        (unsigned long)self.properties.count,
        (unsigned long)self.ivars.count,
        (unsigned long)self.methods.count,
        (unsigned long)self.protocols.count
    ];
}

- (void)examine {
    // cls is a metaclass if self.value is a class
    Class cls = object_getClass(self.value);
    
    unsigned int pcount, mcount, ivcount, pccount;
    objc_property_t *objcproperties     = class_copyPropertyList(cls, &pcount);
    Protocol*__unsafe_unretained *procs = class_copyProtocolList(cls, &pccount);
    Method *objcmethods                 = class_copyMethodList(cls, &mcount);
    Ivar *objcivars                     = class_copyIvarList(cls, &ivcount);
    
    _className = NSStringFromClass(cls);
    _isClass   = class_isMetaClass(cls); // or object_isClass(self.value)
    
    NSMutableArray *properties = [NSMutableArray new];
    for (int i = 0; i < pcount; i++)
        [properties addObject:[FLEXProperty property:objcproperties[i]]];
    _properties = properties;
    
    NSMutableArray *methods = [NSMutableArray new];
    for (int i = 0; i < mcount; i++)
        [methods addObject:[FLEXMethod method:objcmethods[i]]];
    _methods = methods;
    
    NSMutableArray *ivars = [NSMutableArray new];
    for (int i = 0; i < ivcount; i++)
        [ivars addObject:[FLEXIvar ivar:objcivars[i]]];
    _ivars = ivars;
    
    NSMutableArray *protocols = [NSMutableArray new];
    for (int i = 0; i < pccount; i++)
        [protocols addObject:[FLEXProtocol protocol:procs[i]]];
    _protocols = protocols;
    
    // Cleanup
    free(objcproperties);
    free(objcmethods);
    free(objcivars);
    free(procs);
    procs = NULL;
}

#pragma mark Misc

- (FLEXMirror *)superMirror {
    return [FLEXMirror reflect:[self.value superclass]];
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

- (FLEXProperty *)propertyNamed:(NSString *)name {
    return [self filter:self.properties forName:name];
}

- (FLEXIvar *)ivarNamed:(NSString *)name {
    return [self filter:self.ivars forName:name];
}

- (FLEXProtocol *)protocolNamed:(NSString *)name {
    return [self filter:self.protocols forName:name];
}

@end
