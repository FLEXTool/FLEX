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
extern NSString *const kFLEXUtilityAttributeTypeEncoding;
extern NSString *const kFLEXUtilityAttributeBackingIvar;
extern NSString *const kFLEXUtilityAttributeReadOnly;
extern NSString *const kFLEXUtilityAttributeCopy;
extern NSString *const kFLEXUtilityAttributeRetain;
extern NSString *const kFLEXUtilityAttributeNonAtomic;
extern NSString *const kFLEXUtilityAttributeCustomGetter;
extern NSString *const kFLEXUtilityAttributeCustomSetter;
extern NSString *const kFLEXUtilityAttributeDynamic;
extern NSString *const kFLEXUtilityAttributeWeak;
extern NSString *const kFLEXUtilityAttributeGarbageCollectable;
extern NSString *const kFLEXUtilityAttributeOldStyleTypeEncoding;

typedef NS_ENUM(char, FLEXTypeEncoding)
{
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

@interface FLEXRuntimeUtility : NSObject

// General Helpers
+ (BOOL)pointerIsValidObjcObject:(const void *)pointer;
/// Unwraps raw pointers to objects stored in NSValue, and re-boxes C strings into NSStrings.
+ (id)potentiallyUnwrapBoxedPointer:(id)returnedObjectOrNil type:(const FLEXTypeEncoding *)returnType;
/// Some fields have a name in their encoded string (e.g. \"width\"d)
/// @return the offset to skip the field name, 0 if there is no name
+ (NSUInteger)fieldNameOffsetForTypeEncoding:(const FLEXTypeEncoding *)typeEncoding;

/// @return The class hierarchy for the given object or class,
/// from the current class to the root-most class.
+ (NSArray<Class> *)classHierarchyOfObject:(id)objectOrClass;

// Property Helpers
+ (NSString *)prettyNameForProperty:(objc_property_t)property;
+ (NSString *)typeEncodingForProperty:(objc_property_t)property;
+ (BOOL)isReadonlyProperty:(objc_property_t)property;
+ (SEL)setterSelectorForProperty:(objc_property_t)property;
+ (NSString *)fullDescriptionForProperty:(objc_property_t)property;
+ (id)valueForProperty:(objc_property_t)property onObject:(id)object;
+ (NSString *)descriptionForIvarOrPropertyValue:(id)value;
+ (void)tryAddPropertyWithName:(const char *)name attributes:(NSDictionary<NSString *, NSString *> *)attributePairs toClass:(__unsafe_unretained Class)theClass;

// Ivar Helpers
+ (NSString *)prettyNameForIvar:(Ivar)ivar;
+ (id)valueForIvar:(Ivar)ivar onObject:(id)object;
+ (void)setValue:(id)value forIvar:(Ivar)ivar onObject:(id)object;

// Method Helpers
+ (NSString *)prettyNameForMethod:(Method)method isClassMethod:(BOOL)isClassMethod;
+ (NSArray *)prettyArgumentComponentsForMethod:(Method)method;
+ (FLEXTypeEncoding *)returnTypeForMethod:(Method)method;

// Method Calling/Field Editing
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

@end
