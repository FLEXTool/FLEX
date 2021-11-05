//
//  FLEXProperty.m
//  FLEX
//
//  Derived from MirrorKit.
//  Created by Tanner on 6/30/15.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
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
@synthesize imagePath = _imagePath;

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
    objc_property_t _Nullable property = class_getProperty(cls, name.UTF8String);
    NSAssert(property, @"Cannot find property with name %@ on class %@", name, cls);
    return [self property:property onClass:cls];
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
        _name          = @(property_getName(property) ?: "(nil)");
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
    if (self.attributes.typeEncoding.length) {
        _type = (FLEXTypeEncoding)[self.attributes.typeEncoding characterAtIndex:0];
    }

    // Return the given selector if the class responds to it
    Class cls = _cls;
    SEL (^selectorIfValid)(SEL) = ^SEL(SEL sel) {
        if (!sel || !cls) return nil;
        return [cls instancesRespondToSelector:sel] ? sel : nil;
    };

    SEL customGetter = self.attributes.customGetter;
    SEL customSetter = self.attributes.customSetter;
    SEL defaultGetter = NSSelectorFromString(self.name);
    SEL defaultSetter = NSSelectorFromString([NSString
        stringWithFormat:@"set%c%@:",
        (char)toupper([self.name characterAtIndex:0]),
        [self.name substringFromIndex:1]
    ]);

    // Check if the likely getters/setters exist
    SEL validGetter = selectorIfValid(customGetter) ?: selectorIfValid(defaultGetter);
    SEL validSetter = selectorIfValid(customSetter) ?: selectorIfValid(defaultSetter);
    _likelyGetterExists = validGetter != nil;
    _likelySetterExists = validSetter != nil;

    // Assign likely getters and setters to the valid one,
    // or the default, regardless of whether the default exists
    _likelyGetter = validGetter ?: defaultGetter;
    _likelySetter = validSetter ?: defaultSetter;
    _likelyGetterString = NSStringFromSelector(_likelyGetter);
    _likelySetterString = NSStringFromSelector(_likelySetter);

    _isClassProperty = _cls ? class_isMetaClass(_cls) : NO;
    
    _likelyIvarName = _isClassProperty ? nil : (
        self.attributes.backingIvar ?: [@"_" stringByAppendingString:_name]
    );
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
    Dl_info exeInfo;
    if (dladdr(_objc_property, &exeInfo)) {
        _imagePath = exeInfo.dli_fname ? @(exeInfo.dli_fname) : nil;
    }
    
    if ((!_multiple || !_uniqueCheckFlag) && _cls) {
        _multiple = _objc_property != class_getProperty(_cls, self.name.UTF8String);

        if (_multiple || forceBundle) {
            NSString *path = _imagePath.stringByDeletingLastPathComponent;
            _imageName = [NSBundle bundleWithPath:path].executablePath.lastPathComponent;
        }
    }
}

- (BOOL)multiple {
    [self computeSymbolInfo:NO];
    return _multiple;
}

- (NSString *)imagePath {
    [self computeSymbolInfo:YES];
    return _imagePath;
}

- (NSString *)imageName {
    [self computeSymbolInfo:YES];
    return _imageName;
}

- (BOOL)likelyIvarExists {
    if (_likelyIvarName && _cls) {
        return class_getInstanceVariable(_cls, _likelyIvarName.UTF8String) != nil;
    }
    
    return NO;
}

- (NSString *)fullDescription {
    NSMutableArray<NSString *> *attributesStrings = [NSMutableArray new];
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
    
    // Class or not
    if (self.isClassProperty) {
        [attributesStrings addObject:@"class"];
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
    if (!target) return nil;
    
    // We don't care about checking dynamically whether the getter
    // _now_ exists on this object. If the getter doesn't exist
    // when this property is initialized, it will never call it.
    // Just re-create the property object if you need to call it.
    if (self.likelyGetterExists) {
        BOOL objectIsClass = object_isClass(target);
        BOOL instanceAndInstanceProperty = !objectIsClass && !self.isClassProperty;
        BOOL classAndClassProperty = objectIsClass && self.isClassProperty;

        if (instanceAndInstanceProperty || classAndClassProperty) {
            return [FLEXRuntimeUtility performSelector:self.likelyGetter onObject:target];
        }
    }

    return nil;
}

- (id)getPotentiallyUnboxedValue:(id)target {
    if (!target) return nil;

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
