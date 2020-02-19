//
//  FLEXRuntimeUtility.h
//  Flipboard
//
//  Created by Ryan Olson on 6/8/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

extern const unsigned int kFLEXNumberOfImplicitArgs;

// See https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html#//apple_ref/doc/uid/TP40008048-CH101-SW6
extern NSString *const kFLEXPropertyAttributeKeyTypeEncoding;
extern NSString *const kFLEXPropertyAttributeKeyBackingIvarName;
extern NSString *const kFLEXPropertyAttributeKeyReadOnly;
extern NSString *const kFLEXPropertyAttributeKeyCopy;
extern NSString *const kFLEXPropertyAttributeKeyRetain;
extern NSString *const kFLEXPropertyAttributeKeyNonAtomic;
extern NSString *const kFLEXPropertyAttributeKeyCustomGetter;
extern NSString *const kFLEXPropertyAttributeKeyCustomSetter;
extern NSString *const kFLEXPropertyAttributeKeyDynamic;
extern NSString *const kFLEXPropertyAttributeKeyWeak;
extern NSString *const kFLEXPropertyAttributeKeyGarbageCollectable;
extern NSString *const kFLEXPropertyAttributeKeyOldStyleTypeEncoding;

typedef NS_ENUM(NSUInteger, FLEXPropertyAttribute) {
    FLEXPropertyAttributeTypeEncoding       = 'T',
    FLEXPropertyAttributeBackingIvarName    = 'V',
    FLEXPropertyAttributeCopy               = 'C',
    FLEXPropertyAttributeCustomGetter       = 'G',
    FLEXPropertyAttributeCustomSetter       = 'S',
    FLEXPropertyAttributeDynamic            = 'D',
    FLEXPropertyAttributeGarbageCollectible = 'P',
    FLEXPropertyAttributeNonAtomic          = 'N',
    FLEXPropertyAttributeOldTypeEncoding    = 't',
    FLEXPropertyAttributeReadOnly           = 'R',
    FLEXPropertyAttributeRetain             = '&',
    FLEXPropertyAttributeWeak               = 'W'
};

typedef NS_ENUM(char, FLEXTypeEncoding) {
    FLEXTypeEncodingNull             = '\0',
    FLEXTypeEncodingUnknown          = '?',
    FLEXTypeEncodingChar             = 'c',
    FLEXTypeEncodingInt              = 'i',
    FLEXTypeEncodingShort            = 's',
    FLEXTypeEncodingLong             = 'l',
    FLEXTypeEncodingLongLong         = 'q',
    FLEXTypeEncodingUnsignedChar     = 'C',
    FLEXTypeEncodingUnsignedInt      = 'I',
    FLEXTypeEncodingUnsignedShort    = 'S',
    FLEXTypeEncodingUnsignedLong     = 'L',
    FLEXTypeEncodingUnsignedLongLong = 'Q',
    FLEXTypeEncodingFloat            = 'f',
    FLEXTypeEncodingDouble           = 'd',
    FLEXTypeEncodingLongDouble       = 'D',
    FLEXTypeEncodingCBool            = 'B',
    FLEXTypeEncodingVoid             = 'v',
    FLEXTypeEncodingCString          = '*',
    FLEXTypeEncodingObjcObject       = '@',
    FLEXTypeEncodingObjcClass        = '#',
    FLEXTypeEncodingSelector         = ':',
    FLEXTypeEncodingArrayBegin       = '[',
    FLEXTypeEncodingArrayEnd         = ']',
    FLEXTypeEncodingStructBegin      = '{',
    FLEXTypeEncodingStructEnd        = '}',
    FLEXTypeEncodingUnionBegin       = '(',
    FLEXTypeEncodingUnionEnd         = ')',
    FLEXTypeEncodingQuote            = '\"',
    FLEXTypeEncodingBitField         = 'b',
    FLEXTypeEncodingPointer          = '^',
    FLEXTypeEncodingConst            = 'r'
};

#define FLEXEncodeClass(class) ("@\"" #class "\"")
#define FLEXEncodeObject(obj) (obj ? [NSString stringWithFormat:@"@\"%@\"", [obj class]].UTF8String : @encode(id))

#define PropertyKey(suffix) kFLEXPropertyAttributeKey##suffix : @""
#define PropertyKeyGetter(getter) kFLEXPropertyAttributeKeyCustomGetter : NSStringFromSelector(@selector(getter))
#define PropertyKeySetter(setter) kFLEXPropertyAttributeKeyCustomSetter : NSStringFromSelector(@selector(setter))

/// Takes: min iOS version, property name, target class, property type, and a list of attributes
#define FLEXRuntimeUtilityTryAddProperty(iOS_atLeast, name, cls, type, ...) ({ \
    if (@available(iOS iOS_atLeast, *)) { \
        NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithDictionary:@{ \
            kFLEXPropertyAttributeKeyTypeEncoding : @(type), \
            __VA_ARGS__ \
        }]; \
        [FLEXRuntimeUtility \
            tryAddPropertyWithName:#name \
            attributes:attrs \
            toClass:cls \
        ]; \
    } \
})

/// Takes: min iOS version, property name, target class, property type, and a list of attributes
#define FLEXRuntimeUtilityTryAddNonatomicProperty(iOS_atLeast, name, cls, type, ...) \
    FLEXRuntimeUtilityTryAddProperty(iOS_atLeast, name, cls, @encode(type), PropertyKey(NonAtomic), __VA_ARGS__);
/// Takes: min iOS version, property name, target class, property type (class name), and a list of attributes
#define FLEXRuntimeUtilityTryAddObjectProperty(iOS_atLeast, name, cls, type, ...) \
    FLEXRuntimeUtilityTryAddProperty(iOS_atLeast, name, cls, FLEXEncodeClass(type), PropertyKey(NonAtomic), __VA_ARGS__);

@interface FLEXRuntimeUtility : NSObject

// General Helpers
+ (BOOL)pointerIsValidObjcObject:(const void *)pointer;
/// Unwraps raw pointers to objects stored in NSValue, and re-boxes C strings into NSStrings.
+ (id)potentiallyUnwrapBoxedPointer:(id)returnedObjectOrNil type:(const FLEXTypeEncoding *)returnType;
/// Some fields have a name in their encoded string (e.g. \"width\"d)
/// @return the offset to skip the field name, 0 if there is no name
+ (NSUInteger)fieldNameOffsetForTypeEncoding:(const FLEXTypeEncoding *)typeEncoding;
/// Given name "foo" and type "int" this would return "int foo", but
/// given name "foo" and type "T *" it would return "T *foo"
+ (NSString *)appendName:(NSString *)name toType:(NSString *)typeEncoding;

/// @return The class hierarchy for the given object or class,
/// from the current class to the root-most class.
+ (NSArray<Class> *)classHierarchyOfObject:(id)objectOrClass;

/// Used to describe an object in brief within an explorer row
+ (NSString *)summaryForObject:(id)value;
+ (NSString *)safeDescriptionForObject:(id)object;
+ (NSString *)safeDebugDescriptionForObject:(id)object;

// Property Helpers
+ (BOOL)tryAddPropertyWithName:(const char *)name
                    attributes:(NSDictionary<NSString *, NSString *> *)attributePairs
                       toClass:(__unsafe_unretained Class)theClass;
+ (NSArray<NSString *> *)allPropertyAttributeKeys;

// Method Helpers
+ (NSArray *)prettyArgumentComponentsForMethod:(Method)method;

// Method Calling/Field Editing
+ (id)performSelector:(SEL)selector onObject:(id)object;
+ (id)performSelector:(SEL)selector
             onObject:(id)object
        withArguments:(NSArray *)arguments
                error:(NSError * __autoreleasing *)error;
+ (NSString *)editableJSONStringForObject:(id)object;
+ (id)objectValueFromEditableJSONString:(NSString *)string;
+ (NSValue *)valueForNumberWithObjCType:(const char *)typeEncoding fromInputString:(NSString *)inputString;
+ (void)enumerateTypesInStructEncoding:(const char *)structEncoding
                            usingBlock:(void (^)(NSString *structName,
                                                 const char *fieldTypeEncoding,
                                                 NSString *prettyTypeEncoding,
                                                 NSUInteger fieldIndex,
                                                 NSUInteger fieldOffset))typeBlock;
+ (NSValue *)valueForPrimitivePointer:(void *)pointer objCType:(const char *)type;

#pragma mark - Metadata Helpers

+ (NSString *)readableTypeForEncoding:(NSString *)encodingString;

@end
