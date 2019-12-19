//
//  FLEXProperty.m
//  FLEX
//
//  Derived from MirrorKit.
//  Created by Tanner on 6/30/15.
//  Copyright (c) 2015 Tanner Bennett. All rights reserved.
//

#import "FLEXProperty.h"
#import "FLEXPropertyAttributes.h"
#import "FLEXMethodBase.h"
#import "FLEXRuntimeUtility.h"
#include <dlfcn.h>


@interface FLEXProperty () {
    NSString *_flex_description;
}
@property (nonatomic          ) BOOL uniqueCheckFlag;
@property (nonatomic, readonly) Class cls;
@end

@implementation FLEXProperty
@synthesize multiple = _multiple;
@synthesize imageName = _imageName;

#pragma mark Initializers

- (id)init {
    [NSException
        raise:NSInternalInconsistencyException
        format:@"Class instance should not be created with -init"
    ];
    return nil;
}

+ (instancetype)property:(objc_property_t)property {
    return [[self alloc] initWithProperty:property onClass:nil];
}

+ (instancetype)property:(objc_property_t)property onClass:(Class)cls {
    return [[self alloc] initWithProperty:property onClass:cls];
}

+ (instancetype)named:(NSString *)name onClass:(Class)cls {
    return [self property:class_getProperty(cls, name.UTF8String) onClass:cls];
}

+ (instancetype)propertyWithName:(NSString *)name attributes:(FLEXPropertyAttributes *)attributes {
    return [[self alloc] initWithName:name attributes:attributes];
}

- (id)initWithProperty:(objc_property_t)property onClass:(Class)cls {
    NSParameterAssert(property);
    
    self = [super init];
    if (self) {
        _objc_property = property;
        _attributes    = [FLEXPropertyAttributes attributesForProperty:property];
        _name          = @(property_getName(property));
        _cls           = cls;
        
        if (!_attributes) [NSException raise:NSInternalInconsistencyException format:@"Error retrieving property attributes"];
        if (!_name) [NSException raise:NSInternalInconsistencyException format:@"Error retrieving property name"];
        
        [self examine];
    }
    
    return self;
}

- (id)initWithName:(NSString *)name attributes:(FLEXPropertyAttributes *)attributes {
    NSParameterAssert(name); NSParameterAssert(attributes);
    
    self = [super init];
    if (self) {
        _attributes    = attributes;
        _name          = name;
        
        [self examine];
    }
    
    return self;
}

#pragma mark Private

- (void)examine {
    _type = (FLEXTypeEncoding)[self.attributes.typeEncoding characterAtIndex:0];

    _likelyGetter = self.attributes.customGetter ?: NSSelectorFromString(self.name);
    _likelySetter = self.attributes.customSetter ?: NSSelectorFromString([NSString
        stringWithFormat:@"set%c%@:",
        (char)toupper([self.name characterAtIndex:0]),
        [self.name substringFromIndex:1]
    ]);

    if (_cls) {
        _likelySetterExists = [_cls instancesRespondToSelector:_likelySetter];
        _likelyGetterExists = [_cls instancesRespondToSelector:_likelyGetter];
        _isClassProperty = class_isMetaClass(_cls);
    }
}

#pragma mark Overrides

- (NSString *)description {
    if (!_flex_description) {
        NSString *readableType = [FLEXRuntimeUtility readableTypeForEncoding:self.attributes.typeEncoding];
        _flex_description = [FLEXRuntimeUtility appendName:self.name toType:readableType];
    }

    return _flex_description;
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"<%@ name=%@, property=%p, attributes:\n\t%@\n>",
            NSStringFromClass(self.class), self.name, self.objc_property, self.attributes];
}

#pragma mark Public

- (objc_property_attribute_t *)copyAttributesList:(unsigned int *)attributesCount {
    if (self.objc_property) {
        return property_copyAttributeList(self.objc_property, attributesCount);
    } else {
        return [self.attributes copyAttributesList:attributesCount];
    }
}

- (void)replacePropertyOnClass:(Class)cls {
    class_replaceProperty(cls, self.name.UTF8String, self.attributes.list, (unsigned int)self.attributes.count);
}

- (void)computeSymbolInfo:(BOOL)forceBundle {
    if ((!_multiple || !_uniqueCheckFlag) && _cls) {
        _multiple = _objc_property != class_getProperty(_cls, self.name.UTF8String);

        if (_multiple || forceBundle) {
            Dl_info exeInfo;
            dladdr(_objc_property, &exeInfo);
            NSString *path = @(exeInfo.dli_fname).stringByDeletingLastPathComponent;
            _imageName = [NSBundle bundleWithPath:path].executablePath.lastPathComponent;
        }
    }
}

- (BOOL)multiple {
    [self computeSymbolInfo:NO];
    return _multiple;
}

- (NSString *)imageName {
    [self computeSymbolInfo:YES];
    return _imageName;
}

- (NSString *)fullDescription {
    NSMutableArray<NSString *> *attributesStrings = [NSMutableArray array];
    FLEXPropertyAttributes *attributes = self.attributes;

    // Atomicity
    if (attributes.isNonatomic) {
        [attributesStrings addObject:@"nonatomic"];
    } else {
        [attributesStrings addObject:@"atomic"];
    }

    // Storage
    if (attributes.isRetained) {
        [attributesStrings addObject:@"strong"];
    } else if (attributes.isCopy) {
        [attributesStrings addObject:@"copy"];
    } else if (attributes.isWeak) {
        [attributesStrings addObject:@"weak"];
    } else {
        [attributesStrings addObject:@"assign"];
    }

    // Mutability
    if (attributes.isReadOnly) {
        [attributesStrings addObject:@"readonly"];
    } else {
        [attributesStrings addObject:@"readwrite"];
    }

    // Custom getter/setter
    SEL customGetter = attributes.customGetter;
    SEL customSetter = attributes.customSetter;
    if (customGetter) {
        [attributesStrings addObject:[NSString stringWithFormat:@"getter=%s", sel_getName(customGetter)]];
    }
    if (customSetter) {
        [attributesStrings addObject:[NSString stringWithFormat:@"setter=%s", sel_getName(customSetter)]];
    }

    NSString *attributesString = [attributesStrings componentsJoinedByString:@", "];
    return [NSString stringWithFormat:@"@property (%@) %@", attributesString, self.description];
}

- (id)getValue:(id)target {
    // Try custom getter first, then property name
    SEL customGetter = self.attributes.customGetter;
    if (customGetter && [target respondsToSelector:customGetter]) {
        return [target valueForKey:NSStringFromSelector(customGetter)];
    } else if ([target respondsToSelector:NSSelectorFromString(self.name)]) {
        return [target valueForKey:self.name];
    }

    return nil;
}

- (id)getPotentiallyUnboxedValue:(id)target {
    return [FLEXRuntimeUtility
        potentiallyUnwrapBoxedPointer:[self getValue:target]
        type:self.attributes.typeEncoding.UTF8String
    ];
}

#pragma mark Suggested getters and setters

- (FLEXMethodBase *)getterWithImplementation:(IMP)implementation {
    NSString *types        = [NSString stringWithFormat:@"%@%s%s", self.attributes.typeEncoding, @encode(id), @encode(SEL)];
    NSString *name         = [NSString stringWithFormat:@"%@", self.name];
    FLEXMethodBase *getter = [FLEXMethodBase buildMethodNamed:name withTypes:types implementation:implementation];
    return getter;
}

- (FLEXMethodBase *)setterWithImplementation:(IMP)implementation {
    NSString *types        = [NSString stringWithFormat:@"%s%s%s%@", @encode(void), @encode(id), @encode(SEL), self.attributes.typeEncoding];
    NSString *name         = [NSString stringWithFormat:@"set%@:", self.name.capitalizedString];
    FLEXMethodBase *setter = [FLEXMethodBase buildMethodNamed:name withTypes:types implementation:implementation];
    return setter;
}

@end
