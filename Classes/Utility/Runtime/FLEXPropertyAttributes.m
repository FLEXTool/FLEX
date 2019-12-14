//
//  FLEXPropertyAttributes.m
//  FLEX
//
//  Derived from MirrorKit.
//  Created by Tanner on 7/5/15.
//  Copyright (c) 2015 Tanner Bennett. All rights reserved.
//

#import "FLEXPropertyAttributes.h"
#import "FLEXRuntimeUtility.h"
#import "NSString+ObjcRuntime.h"
#import "NSDictionary+ObjcRuntime.h"


#pragma mark FLEXPropertyAttributes

@interface FLEXPropertyAttributes ()

@property (nonatomic) NSString *backingIvar;
@property (nonatomic) NSString *typeEncoding;
@property (nonatomic) NSString *oldTypeEncoding;
@property (nonatomic) SEL customGetter;
@property (nonatomic) SEL customSetter;
@property (nonatomic) BOOL isReadOnly;
@property (nonatomic) BOOL isCopy;
@property (nonatomic) BOOL isRetained;
@property (nonatomic) BOOL isNonatomic;
@property (nonatomic) BOOL isDynamic;
@property (nonatomic) BOOL isWeak;
@property (nonatomic) BOOL isGarbageCollectable;

@end

@implementation FLEXPropertyAttributes
@synthesize list = _list;

#pragma mark Initializers

+ (instancetype)attributesForProperty:(objc_property_t)property {
    return [self attributesFromString:@(property_getAttributes(property))];
}

+ (instancetype)attributesFromDictionary:(NSDictionary *)attributes {
    NSString *attrs = attributes.propertyAttributesString;
    if (!attrs) {
        [NSException raise:NSInternalInconsistencyException
                    format:@"Invalid property attributes dictionary: %@", attributes];
    }
    return [self attributesFromString:attrs];
}

+ (instancetype)attributesFromString:(NSString *)attributes {
    return [[self alloc] initWithstring:attributes];
}

- (id)initWithstring:(NSString *)string {
    NSParameterAssert(string);
    
    self = [super init];
    if (self) {
        _string = string;
        
        _dictionary = string.propertyAttributes;
        if (!_dictionary) {
            [NSException raise:NSInternalInconsistencyException
                        format:@"Invalid property attributes string: %@", string];
        }
        
        _count                = _dictionary.count;
        _typeEncoding         = _dictionary[kFLEXPropertyAttributeKeyTypeEncoding];
        _backingIvar          = _dictionary[kFLEXPropertyAttributeKeyBackingIvarName];
        _oldTypeEncoding      = _dictionary[kFLEXPropertyAttributeKeyOldStyleTypeEncoding];
        _customGetter         = NSSelectorFromString(_dictionary[kFLEXPropertyAttributeKeyCustomGetter]);
        _customSetter         = NSSelectorFromString(_dictionary[kFLEXPropertyAttributeKeyCustomSetter]);
        _isReadOnly           = [_dictionary[kFLEXPropertyAttributeKeyReadOnly] boolValue];
        _isCopy               = [_dictionary[kFLEXPropertyAttributeKeyCopy] boolValue];
        _isRetained           = [_dictionary[kFLEXPropertyAttributeKeyRetain] boolValue];
        _isNonatomic          = [_dictionary[kFLEXPropertyAttributeKeyNonAtomic] boolValue];
        _isWeak               = [_dictionary[kFLEXPropertyAttributeKeyWeak] boolValue];
        _isGarbageCollectable = [_dictionary[kFLEXPropertyAttributeKeyGarbageCollectable] boolValue];
    }
    
    return self;
}

#pragma mark Misc

- (NSString *)description {
    return [NSString
        stringWithFormat:@"<%@ ivar=%@, readonly=%d, nonatomic=%d, getter=%@, setter=%@>\n%@",
        NSStringFromClass(self.class),
        self.backingIvar ?: @"none",
        self.isReadOnly,
        self.isNonatomic,
        NSStringFromSelector(self.customGetter) ?: @" ",
        NSStringFromSelector(self.customSetter) ?: @" ",
        self.string
    ];
}

- (objc_property_attribute_t *)copyAttributesList:(unsigned int *)attributesCount {
    NSDictionary *attrs = self.string.propertyAttributes;
    objc_property_attribute_t *propertyAttributes = malloc(attrs.count * sizeof(objc_property_attribute_t));

    if (attributesCount) {
        *attributesCount = (unsigned int)attrs.count;
    }
    
    NSUInteger i = 0;
    for (NSString *key in attrs.allKeys) {
        FLEXPropertyAttribute c = (FLEXPropertyAttribute)[key characterAtIndex:0];
        switch (c) {
            case FLEXPropertyAttributeTypeEncoding: {
                objc_property_attribute_t pa = {
                    kFLEXPropertyAttributeKeyTypeEncoding.UTF8String,
                    self.typeEncoding.UTF8String
                };
                propertyAttributes[i] = pa;
                break;
            }
            case FLEXPropertyAttributeBackingIvarName: {
                objc_property_attribute_t pa = {
                    kFLEXPropertyAttributeKeyBackingIvarName.UTF8String,
                    self.backingIvar.UTF8String
                };
                propertyAttributes[i] = pa;
                break;
            }
            case FLEXPropertyAttributeCopy: {
                objc_property_attribute_t pa = {kFLEXPropertyAttributeKeyCopy.UTF8String, ""};
                propertyAttributes[i] = pa;
                break;
            }
            case FLEXPropertyAttributeCustomGetter: {
                objc_property_attribute_t pa = {
                    kFLEXPropertyAttributeKeyCustomGetter.UTF8String,
                    NSStringFromSelector(self.customGetter).UTF8String ?: ""
                };
                propertyAttributes[i] = pa;
                break;
            }
            case FLEXPropertyAttributeCustomSetter: {
                objc_property_attribute_t pa = {
                    kFLEXPropertyAttributeKeyCustomSetter.UTF8String,
                    NSStringFromSelector(self.customSetter).UTF8String ?: ""
                };
                propertyAttributes[i] = pa;
                break;
            }
            case FLEXPropertyAttributeDynamic: {
                objc_property_attribute_t pa = {kFLEXPropertyAttributeKeyDynamic.UTF8String, ""};
                propertyAttributes[i] = pa;
                break;
            }
            case FLEXPropertyAttributeGarbageCollectible: {
                objc_property_attribute_t pa = {kFLEXPropertyAttributeKeyGarbageCollectable.UTF8String, ""};
                propertyAttributes[i] = pa;
                break;
            }
            case FLEXPropertyAttributeNonAtomic: {
                objc_property_attribute_t pa = {kFLEXPropertyAttributeKeyNonAtomic.UTF8String, ""};
                propertyAttributes[i] = pa;
                break;
            }
            case FLEXPropertyAttributeOldTypeEncoding: {
                objc_property_attribute_t pa = {
                    kFLEXPropertyAttributeKeyOldStyleTypeEncoding.UTF8String,
                    self.oldTypeEncoding.UTF8String ?: ""
                };
                propertyAttributes[i] = pa;
                break;
            }
            case FLEXPropertyAttributeReadOnly: {
                objc_property_attribute_t pa = {kFLEXPropertyAttributeKeyReadOnly.UTF8String, ""};
                propertyAttributes[i] = pa;
                break;
            }
            case FLEXPropertyAttributeRetain: {
                objc_property_attribute_t pa = {kFLEXPropertyAttributeKeyRetain.UTF8String, ""};
                propertyAttributes[i] = pa;
                break;
            }
            case FLEXPropertyAttributeWeak: {
                objc_property_attribute_t pa = {kFLEXPropertyAttributeKeyWeak.UTF8String, ""};
                propertyAttributes[i] = pa;
                break;
            }
        }
        i++;
    }
    
    return propertyAttributes;
}

- (objc_property_attribute_t *)list {
    if (!_list) {
        _list = [self copyAttributesList:nil];
    }

    return _list;
}

- (void)dealloc {
    if (_list) {
        free(_list);
        _list = nil;
    }
}

#pragma mark Copying

- (id)copyWithZone:(NSZone *)zone {
    return [[FLEXPropertyAttributes class] attributesFromString:self.string];
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    return [[FLEXMutablePropertyAttributes class] attributesFromString:self.string];
}

@end



#pragma mark FLEXMutablePropertyAttributes

@interface FLEXMutablePropertyAttributes ()
@property (nonatomic) BOOL countDelta;
@property (nonatomic) BOOL stringDelta;
@property (nonatomic) BOOL dictDelta;
@property (nonatomic) BOOL listDelta;
@end

#define PropertyWithDeltaFlag(type, name, Name) @dynamic name; \
- (void)set ## Name:(type)name { \
    if (name != _ ## name) { \
        _countDelta = _stringDelta = _dictDelta = _listDelta = YES; \
        _ ## name = name; \
    } \
}

@implementation FLEXMutablePropertyAttributes

PropertyWithDeltaFlag(NSString *, backingIvar, BackingIvar);
PropertyWithDeltaFlag(NSString *, typeEncoding, TypeEncoding);
PropertyWithDeltaFlag(NSString *, oldTypeEncoding, OldTypeEncoding);
PropertyWithDeltaFlag(SEL, customGetter, CustomGetter);
PropertyWithDeltaFlag(SEL, customSetter, CustomSetter);
PropertyWithDeltaFlag(BOOL, isReadOnly, IsReadOnly);
PropertyWithDeltaFlag(BOOL, isCopy, IsCopy);
PropertyWithDeltaFlag(BOOL, isRetained, IsRetained);
PropertyWithDeltaFlag(BOOL, isNonatomic, IsNonatomic);
PropertyWithDeltaFlag(BOOL, isDynamic, IsDynamic);
PropertyWithDeltaFlag(BOOL, isWeak, IsWeak);
PropertyWithDeltaFlag(BOOL, isGarbageCollectable, IsGarbageCollectable);

+ (instancetype)attributes {
    return [self new];
}

- (void)setTypeEncodingChar:(char)type {
    self.typeEncoding = [NSString stringWithFormat:@"%c", type];
}

- (NSUInteger)count {
    // Recalculate attribute count after mutations
    if (self.countDelta) {
        self.countDelta = NO;
        _count = self.dictionary.count;
    }

    return _count;
}

- (objc_property_attribute_t *)list {
    // Regenerate list after mutations
    if (self.listDelta) {
        self.listDelta = NO;
        if (_list) {
            free(_list);
            _list = nil;
        }
    }

    // Super will generate the list if it isn't set
    return super.list;
}

- (NSString *)string {
    // Regenerate string after mutations
    if (self.stringDelta || !_string) {
        self.stringDelta = NO;
        _string = self.dictionary.propertyAttributesString;
    }

    return _string;
}

- (NSDictionary *)dictionary {
    // Regenerate dictionary after mutations
    if (self.dictDelta || !_dictionary) {
        // _stringa nd _dictionary depend on each other,
        // so we must generate ONE by hand using our properties.
        // We arbitrarily choose to generate the dictionary.
        NSMutableDictionary *attrs = [NSMutableDictionary new];
        if (self.typeEncoding)
            attrs[kFLEXPropertyAttributeKeyTypeEncoding]         = self.typeEncoding;
        if (self.backingIvar)
            attrs[kFLEXPropertyAttributeKeyBackingIvarName]      = self.backingIvar;
        if (self.oldTypeEncoding)
            attrs[kFLEXPropertyAttributeKeyOldStyleTypeEncoding] = self.oldTypeEncoding;
        if (self.customGetter)
            attrs[kFLEXPropertyAttributeKeyCustomGetter]         = NSStringFromSelector(self.customGetter);
        if (self.customSetter)
            attrs[kFLEXPropertyAttributeKeyCustomSetter]         = NSStringFromSelector(self.customSetter);

        if (self.isReadOnly)           attrs[kFLEXPropertyAttributeKeyReadOnly] = @YES;
        if (self.isCopy)               attrs[kFLEXPropertyAttributeKeyCopy] = @YES;
        if (self.isRetained)           attrs[kFLEXPropertyAttributeKeyRetain] = @YES;
        if (self.isNonatomic)          attrs[kFLEXPropertyAttributeKeyNonAtomic] = @YES;
        if (self.isDynamic)            attrs[kFLEXPropertyAttributeKeyDynamic] = @YES;
        if (self.isWeak)               attrs[kFLEXPropertyAttributeKeyWeak] = @YES;
        if (self.isGarbageCollectable) attrs[kFLEXPropertyAttributeKeyGarbageCollectable] = @YES;

        _dictionary = attrs.copy;
    }

    return _dictionary;
}

@end
