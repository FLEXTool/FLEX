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

// See https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html#//apple_ref/doc/uid/TP40008048-CH101-SW6
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

#define FLEXEncodeClass(class) ("@\"" #class "\"")

@interface FLEXRuntimeUtility : NSObject

// Property Helpers
+ (NSString *)prettyNameForProperty:(objc_property_t)property;
+ (NSString *)typeEncodingForProperty:(objc_property_t)property;
+ (BOOL)isReadonlyProperty:(objc_property_t)property;
+ (SEL)setterSelectorForProperty:(objc_property_t)property;
+ (NSString *)fullDescriptionForProperty:(objc_property_t)property;
+ (id)valueForProperty:(objc_property_t)property onObject:(id)object;
+ (NSString *)descriptionForIvarOrPropertyValue:(id)value;
+ (void)tryAddPropertyWithName:(const char *)name attributes:(NSDictionary *)attributePairs toClass:(__unsafe_unretained Class)theClass;

// Ivar Helpers
+ (NSString *)prettyNameForIvar:(Ivar)ivar;
+ (id)valueForIvar:(Ivar)ivar onObject:(id)object;
+ (void)setValue:(id)value forIvar:(Ivar)ivar onObject:(id)object;

// Method Helpers
+ (NSString *)prettyNameForMethod:(Method)method isClassMethod:(BOOL)isClassMethod;
+ (NSArray *)prettyArgumentComponentsForMethod:(Method)method;

// Method Calling/Field Editing
+ (id)performSelector:(SEL)selector onObject:(id)object withArguments:(NSArray *)arguments error:(NSError * __autoreleasing *)error;
+ (NSString *)editableJSONStringForObject:(id)object;
+ (id)objectValueFromEditableJSONString:(NSString *)string;
+ (NSValue *)valueForNumberWithObjCType:(const char *)typeEncoding fromInputString:(NSString *)inputString;
+ (void)enumerateTypesInStructEncoding:(const char *)structEncoding usingBlock:(void (^)(NSString *structName, const char *fieldTypeEncoding, NSString *prettyTypeEncoding, NSUInteger fieldIndex, NSUInteger fieldOffset))typeBlock;
+ (NSValue *)valueForPrimitivePointer:(void *)pointer objCType:(const char *)type;

@end
