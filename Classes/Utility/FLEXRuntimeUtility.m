//
//  FLEXRuntimeUtility.m
//  Flipboard
//
//  Created by Ryan Olson on 6/8/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FLEXRuntimeUtility.h"

// See https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html#//apple_ref/doc/uid/TP40008048-CH101-SW6
NSString *const kFLEXUtilityAttributeTypeEncoding = @"T";
NSString *const kFLEXUtilityAttributeBackingIvar = @"V";
NSString *const kFLEXUtilityAttributeReadOnly = @"R";
NSString *const kFLEXUtilityAttributeCopy = @"C";
NSString *const kFLEXUtilityAttributeRetain = @"&";
NSString *const kFLEXUtilityAttributeNonAtomic = @"N";
NSString *const kFLEXUtilityAttributeCustomGetter = @"G";
NSString *const kFLEXUtilityAttributeCustomSetter = @"S";
NSString *const kFLEXUtilityAttributeDynamic = @"D";
NSString *const kFLEXUtilityAttributeWeak = @"W";
NSString *const kFLEXUtilityAttributeGarbageCollectable = @"P";
NSString *const kFLEXUtilityAttributeOldStyleTypeEncoding = @"t";

static NSString *const FLEXRuntimeUtilityErrorDomain = @"FLEXRuntimeUtilityErrorDomain";
typedef NS_ENUM(NSInteger, FLEXRuntimeUtilityErrorCode) {
    FLEXRuntimeUtilityErrorCodeDoesNotRecognizeSelector = 0,
    FLEXRuntimeUtilityErrorCodeInvocationFailed = 1,
    FLEXRuntimeUtilityErrorCodeArgumentTypeMismatch = 2
};

// Arguments 0 and 1 are self and _cmd always
const unsigned int kFLEXNumberOfImplicitArgs = 2;

@implementation FLEXRuntimeUtility


#pragma mark - Property Helpers (Public)

+ (NSString *)prettyNameForProperty:(objc_property_t)property
{
    NSString *name = @(property_getName(property));
    NSString *encoding = [self typeEncodingForProperty:property];
    NSString *readableType = [self readableTypeForEncoding:encoding];
    return [self appendName:name toType:readableType];
}

+ (NSString *)typeEncodingForProperty:(objc_property_t)property
{
    NSDictionary *attributesDictionary = [self attributesDictionaryForProperty:property];
    return attributesDictionary[kFLEXUtilityAttributeTypeEncoding];
}

+ (BOOL)isReadonlyProperty:(objc_property_t)property
{
    return [[self attributesDictionaryForProperty:property] objectForKey:kFLEXUtilityAttributeReadOnly] != nil;
}

+ (SEL)setterSelectorForProperty:(objc_property_t)property
{
    SEL setterSelector = NULL;
    NSString *setterSelectorString = [[self attributesDictionaryForProperty:property] objectForKey:kFLEXUtilityAttributeCustomSetter];
    if (!setterSelectorString) {
        NSString *propertyName = @(property_getName(property));
        setterSelectorString = [NSString stringWithFormat:@"set%@%@:", [[propertyName substringToIndex:1] uppercaseString], [propertyName substringFromIndex:1]];
    }
    if (setterSelectorString) {
        setterSelector = NSSelectorFromString(setterSelectorString);
    }
    return setterSelector;
}

+ (NSString *)fullDescriptionForProperty:(objc_property_t)property
{
    NSDictionary *attributesDictionary = [self attributesDictionaryForProperty:property];
    NSMutableArray *attributesStrings = [NSMutableArray array];
    
    // Atomicity
    if (attributesDictionary[kFLEXUtilityAttributeNonAtomic]) {
        [attributesStrings addObject:@"nonatomic"];
    } else {
        [attributesStrings addObject:@"atomic"];
    }
    
    // Storage
    if (attributesDictionary[kFLEXUtilityAttributeRetain]) {
        [attributesStrings addObject:@"strong"];
    } else if (attributesDictionary[kFLEXUtilityAttributeCopy]) {
        [attributesStrings addObject:@"copy"];
    } else if (attributesDictionary[kFLEXUtilityAttributeWeak]) {
        [attributesStrings addObject:@"weak"];
    } else {
        [attributesStrings addObject:@"assign"];
    }
    
    // Mutability
    if (attributesDictionary[kFLEXUtilityAttributeReadOnly]) {
        [attributesStrings addObject:@"readonly"];
    } else {
        [attributesStrings addObject:@"readwrite"];
    }
    
    // Custom getter/setter
    NSString *customGetter = attributesDictionary[kFLEXUtilityAttributeCustomGetter];
    NSString *customSetter = attributesDictionary[kFLEXUtilityAttributeCustomSetter];
    if (customGetter) {
        [attributesStrings addObject:[NSString stringWithFormat:@"getter=%@", customGetter]];
    }
    if (customSetter) {
        [attributesStrings addObject:[NSString stringWithFormat:@"setter=%@", customSetter]];
    }
    
    NSString *attributesString = [attributesStrings componentsJoinedByString:@", "];
    NSString *shortName = [self prettyNameForProperty:property];
    
    return [NSString stringWithFormat:@"@property (%@) %@", attributesString, shortName];
}

+ (id)valueForProperty:(objc_property_t)property onObject:(id)object
{
    NSString *customGetterString = nil;
    char *customGetterName = property_copyAttributeValue(property, "G");
    if (customGetterName) {
        customGetterString = @(customGetterName);
        free(customGetterName);
    }
    
    SEL getterSelector;
    if ([customGetterString length] > 0) {
        getterSelector = NSSelectorFromString(customGetterString);
    } else {
        NSString *propertyName = @(property_getName(property));
        getterSelector = NSSelectorFromString(propertyName);
    }
    
    return [self performSelector:getterSelector onObject:object withArguments:nil error:NULL];
}

+ (NSString *)descriptionForIvarOrPropertyValue:(id)value
{
    NSString *description = nil;
    
    // Special case BOOL for better readability.
    if ([value isKindOfClass:[NSValue class]]) {
        const char *type = [value objCType];
        if (strcmp(type, @encode(BOOL)) == 0) {
            BOOL boolValue = NO;
            [value getValue:&boolValue];
            description = boolValue ? @"YES" : @"NO";
        } else if (strcmp(type, @encode(SEL)) == 0) {
            SEL selector = NULL;
            [value getValue:&selector];
            description = NSStringFromSelector(selector);
        }
    }
    
    if (!description) {
        // Single line display - replace newlines and tabs with spaces.
        description = [[value description] stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        description = [description stringByReplacingOccurrencesOfString:@"\t" withString:@" "];
    }
    
    if (!description) {
        description = @"nil";
    }
    
    return description;
}

+ (void)tryAddPropertyWithName:(const char *)name attributes:(NSDictionary *)attributePairs toClass:(__unsafe_unretained Class)theClass
{
    objc_property_t property = class_getProperty(theClass, name);
    if (!property) {
        unsigned int totalAttributesCount = (unsigned int)[attributePairs count];
        objc_property_attribute_t *attributes = malloc(sizeof(objc_property_attribute_t) * totalAttributesCount);
        if (attributes) {
            unsigned int attributeIndex = 0;
            for (NSString *attributeName in [attributePairs allKeys]) {
                objc_property_attribute_t attribute;
                attribute.name = [attributeName UTF8String];
                attribute.value = [attributePairs[attributeName] UTF8String];
                attributes[attributeIndex++] = attribute;
            }
            
            class_addProperty(theClass, name, attributes, totalAttributesCount);
            free(attributes);
        }
    }
}


#pragma mark - Ivar Helpers (Public)

+ (NSString *)prettyNameForIvar:(Ivar)ivar
{
    const char *nameCString = ivar_getName(ivar);
    NSString *name = nameCString ? @(nameCString) : nil;
    const char *encodingCString = ivar_getTypeEncoding(ivar);
    NSString *encoding = encodingCString ? @(encodingCString) : nil;
    NSString *readableType = [self readableTypeForEncoding:encoding];
    return [self appendName:name toType:readableType];
}

+ (id)valueForIvar:(Ivar)ivar onObject:(id)object
{
    id value = nil;
    const char *type = ivar_getTypeEncoding(ivar);
#ifdef __arm64__
    // See http://www.sealiesoftware.com/blog/archive/2013/09/24/objc_explain_Non-pointer_isa.html
    const char *name = ivar_getName(ivar);
    if (type[0] == @encode(Class)[0] && strcmp(name, "isa") == 0) {
        value = object_getClass(object);
    } else
#endif
    if (type[0] == @encode(id)[0] || type[0] == @encode(Class)[0]) {
        value = object_getIvar(object, ivar);
    } else {
        ptrdiff_t offset = ivar_getOffset(ivar);
        void *pointer = (__bridge void *)object + offset;
        value = [self valueForPrimitivePointer:pointer objCType:type];
    }
    return value;
}

+ (void)setValue:(id)value forIvar:(Ivar)ivar onObject:(id)object
{
    const char *typeEncodingCString = ivar_getTypeEncoding(ivar);
    if (typeEncodingCString[0] == '@') {
        object_setIvar(object, ivar, value);
    } else if ([value isKindOfClass:[NSValue class]]) {
        // Primitive - unbox the NSValue.
        NSValue *valueValue = (NSValue *)value;
        
        // Make sure that the box contained the correct type.
        NSAssert(strcmp([valueValue objCType], typeEncodingCString) == 0, @"Type encoding mismatch (value: %s; ivar: %s) in setting ivar named: %s on object: %@", [valueValue objCType], typeEncodingCString, ivar_getName(ivar), object);
        
        NSUInteger bufferSize = 0;
        @try {
            // NSGetSizeAndAlignment barfs on type encoding for bitfields.
            NSGetSizeAndAlignment(typeEncodingCString, &bufferSize, NULL);
        } @catch (NSException *exception) { }
        if (bufferSize > 0) {
            void *buffer = calloc(bufferSize, 1);
            [valueValue getValue:buffer];
            ptrdiff_t offset = ivar_getOffset(ivar);
            void *pointer = (__bridge void *)object + offset;
            memcpy(pointer, buffer, bufferSize);
            free(buffer);
        }
    }
}


#pragma mark - Method Helpers (Public)

+ (NSString *)prettyNameForMethod:(Method)method isClassMethod:(BOOL)isClassMethod
{
    NSString *selectorName = NSStringFromSelector(method_getName(method));
    NSString *methodTypeString = isClassMethod ? @"+" : @"-";
    char *returnType = method_copyReturnType(method);
    NSString *readableReturnType = [self readableTypeForEncoding:@(returnType)];
    free(returnType);
    NSString *prettyName = [NSString stringWithFormat:@"%@ (%@)", methodTypeString, readableReturnType];
    NSArray *components = [self prettyArgumentComponentsForMethod:method];
    if ([components count] > 0) {
        prettyName = [prettyName stringByAppendingString:[components componentsJoinedByString:@" "]];
    } else {
        prettyName = [prettyName stringByAppendingString:selectorName];
    }
    
    return prettyName;
}

+ (NSArray *)prettyArgumentComponentsForMethod:(Method)method
{
    NSMutableArray *components = [NSMutableArray array];
    
    NSString *selectorName = NSStringFromSelector(method_getName(method));
    NSArray *selectorComponents = [selectorName componentsSeparatedByString:@":"];
    unsigned int numberOfArguments = method_getNumberOfArguments(method);
    
    for (unsigned int argIndex = kFLEXNumberOfImplicitArgs; argIndex < numberOfArguments; argIndex++) {
        char *argType = method_copyArgumentType(method, argIndex);
        NSString *readableArgType = [self readableTypeForEncoding:@(argType)];
        free(argType);
        NSString *prettyComponent = [NSString stringWithFormat:@"%@:(%@) ", [selectorComponents objectAtIndex:argIndex - kFLEXNumberOfImplicitArgs], readableArgType];
        [components addObject:prettyComponent];
    }
    
    return components;
}


#pragma mark - Method Calling/Field Editing (Public)

+ (id)performSelector:(SEL)selector onObject:(id)object withArguments:(NSArray *)arguments error:(NSError * __autoreleasing *)error
{
    // Bail if the object won't respond to this selector.
    if (![object respondsToSelector:selector]) {
        if (error) {
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : [NSString stringWithFormat:@"%@ does not respond to the selector %@", object, NSStringFromSelector(selector)]};
            *error = [NSError errorWithDomain:FLEXRuntimeUtilityErrorDomain code:FLEXRuntimeUtilityErrorCodeDoesNotRecognizeSelector userInfo:userInfo];
        }
        return nil;
    }
    
    // Build the invocation
    NSMethodSignature *methodSignature = [object methodSignatureForSelector:selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    [invocation setSelector:selector];
    [invocation setTarget:object];
    [invocation retainArguments];
    
    // Always self and _cmd
    NSUInteger numberOfArguments = [methodSignature numberOfArguments];
    for (NSUInteger argumentIndex = kFLEXNumberOfImplicitArgs; argumentIndex < numberOfArguments; argumentIndex++) {
        NSUInteger argumentsArrayIndex = argumentIndex - kFLEXNumberOfImplicitArgs;
        id argumentObject = [arguments count] > argumentsArrayIndex ? arguments[argumentsArrayIndex] : nil;
        
        // NSNull in the arguments array can be passed as a placeholder to indicate nil. We only need to set the argument if it will be non-nil.
        if (argumentObject && ![argumentObject isKindOfClass:[NSNull class]]) {
            const char *typeEncodingCString = [methodSignature getArgumentTypeAtIndex:argumentIndex];
            if (typeEncodingCString[0] == @encode(id)[0] || typeEncodingCString[0] == @encode(Class)[0] || [self isTollFreeBridgedValue:argumentObject forCFType:typeEncodingCString]) {
                // Object
                [invocation setArgument:&argumentObject atIndex:argumentIndex];
            } else if (strcmp(typeEncodingCString, @encode(CGColorRef)) == 0 && [argumentObject isKindOfClass:[UIColor class]]) {
                // Bridging UIColor to CGColorRef
                CGColorRef colorRef = [argumentObject CGColor];
                [invocation setArgument:&colorRef atIndex:argumentIndex];
            } else if ([argumentObject isKindOfClass:[NSValue class]]) {
                // Primitive boxed in NSValue
                NSValue *argumentValue = (NSValue *)argumentObject;
                
                // Ensure that the type encoding on the NSValue matches the type encoding of the argument in the method signature
                if (strcmp([argumentValue objCType], typeEncodingCString) != 0) {
                    if (error) {
                        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Type encoding mismatch for agrument at index %lu. Value type: %s; Method argument type: %s.", (unsigned long)argumentsArrayIndex, [argumentValue objCType], typeEncodingCString]};
                        *error = [NSError errorWithDomain:FLEXRuntimeUtilityErrorDomain code:FLEXRuntimeUtilityErrorCodeArgumentTypeMismatch userInfo:userInfo];
                    }
                    return nil;
                }
                
                NSUInteger bufferSize = 0;
                @try {
                    // NSGetSizeAndAlignment barfs on type encoding for bitfields.
                    NSGetSizeAndAlignment(typeEncodingCString, &bufferSize, NULL);
                } @catch (NSException *exception) { }
                
                if (bufferSize > 0) {
                    void *buffer = calloc(bufferSize, 1);
                    [argumentValue getValue:buffer];
                    [invocation setArgument:buffer atIndex:argumentIndex];
                    free(buffer);
                }
            }
        }
    }
    
    // Try to invoke the invocation but guard against an exception being thrown.
    BOOL successfullyInvoked = NO;
    @try {
        // Some methods are not fit to be called...
        // Looking at you -[UIResponder(UITextInputAdditions) _caretRect]
        [invocation invoke];
        successfullyInvoked = YES;
    } @catch (NSException *exception) {
        // Bummer...
        if (error) {
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Exception thrown while performing selector %@ on object %@", NSStringFromSelector(selector), object]};
            *error = [NSError errorWithDomain:FLEXRuntimeUtilityErrorDomain code:FLEXRuntimeUtilityErrorCodeInvocationFailed userInfo:userInfo];
        }
    }
    
    // Retreive the return value and box if necessary.
    id returnObject = nil;
    if (successfullyInvoked) {
        const char *returnType = [methodSignature methodReturnType];
        if (returnType[0] == @encode(id)[0] || returnType[0] == @encode(Class)[0]) {
            __unsafe_unretained id objectReturnedFromMethod = nil;
            [invocation getReturnValue:&objectReturnedFromMethod];
            returnObject = objectReturnedFromMethod;
        } else if (returnType[0] != @encode(void)[0]) {
            void *returnValue = malloc([methodSignature methodReturnLength]);
            if (returnValue) {
                [invocation getReturnValue:returnValue];
                returnObject = [self valueForPrimitivePointer:returnValue objCType:returnType];
                free(returnValue);
            }
        }
    }
    
    return returnObject;
}

+ (BOOL)isTollFreeBridgedValue:(id)value forCFType:(const char *)typeEncoding
{
    // See https://developer.apple.com/library/ios/documentation/general/conceptual/CocoaEncyclopedia/Toll-FreeBridgin/Toll-FreeBridgin.html
#define CASE(cftype, foundationClass) \
    if(strcmp(typeEncoding, @encode(cftype)) == 0) { \
        return [value isKindOfClass:[foundationClass class]]; \
    }
    
    CASE(CFArrayRef, NSArray);
    CASE(CFAttributedStringRef, NSAttributedString);
    CASE(CFCalendarRef, NSCalendar);
    CASE(CFCharacterSetRef, NSCharacterSet);
    CASE(CFDataRef, NSData);
    CASE(CFDateRef, NSDate);
    CASE(CFDictionaryRef, NSDictionary);
    CASE(CFErrorRef, NSError);
    CASE(CFLocaleRef, NSLocale);
    CASE(CFMutableArrayRef, NSMutableArray);
    CASE(CFMutableAttributedStringRef, NSMutableAttributedString);
    CASE(CFMutableCharacterSetRef, NSMutableCharacterSet);
    CASE(CFMutableDataRef, NSMutableData);
    CASE(CFMutableDictionaryRef, NSMutableDictionary);
    CASE(CFMutableSetRef, NSMutableSet);
    CASE(CFMutableStringRef, NSMutableString);
    CASE(CFNumberRef, NSNumber);
    CASE(CFReadStreamRef, NSInputStream);
    CASE(CFRunLoopTimerRef, NSTimer);
    CASE(CFSetRef, NSSet);
    CASE(CFStringRef, NSString);
    CASE(CFTimeZoneRef, NSTimeZone);
    CASE(CFURLRef, NSURL);
    CASE(CFWriteStreamRef, NSOutputStream);
    
#undef CASE
    
    return NO;
}

+ (NSString *)editableJSONStringForObject:(id)object
{
    NSString *editableDescription = nil;
    
    if (object) {
        // This is a hack to use JSON serialization for our editable objects.
        // NSJSONSerialization doesn't allow writing fragments - the top level object must be an array or dictionary.
        // We always wrap the object inside an array and then strip the outer square braces off the final string.
        NSArray *wrappedObject = @[object];
        if ([NSJSONSerialization isValidJSONObject:wrappedObject]) {
            NSString *wrappedDescription = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:wrappedObject options:0 error:NULL] encoding:NSUTF8StringEncoding];
            editableDescription = [wrappedDescription substringWithRange:NSMakeRange(1, [wrappedDescription length] - 2)];
        }
    }
    
    return editableDescription;
}

+ (id)objectValueFromEditableJSONString:(NSString *)string
{
    id value = nil;
    // nil for empty string/whitespace
    if ([[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0) {
        value = [NSJSONSerialization JSONObjectWithData:[string dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:NULL];
    }
    return value;
}

+ (NSValue *)valueForNumberWithObjCType:(const char *)typeEncoding fromInputString:(NSString *)inputString
{
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    NSNumber *number = [formatter numberFromString:inputString];
    
    // Make sure we box the number with the correct type encoding so it can be propperly unboxed later via getValue:
    NSValue *value = nil;
    if (strcmp(typeEncoding, @encode(char)) == 0) {
        char primitiveValue = [number charValue];
        value = [NSValue value:&primitiveValue withObjCType:typeEncoding];
    } else if (strcmp(typeEncoding, @encode(int)) == 0) {
        int primitiveValue = [number intValue];
        value = [NSValue value:&primitiveValue withObjCType:typeEncoding];
    } else if (strcmp(typeEncoding, @encode(short)) == 0) {
        short primitiveValue = [number shortValue];
        value = [NSValue value:&primitiveValue withObjCType:typeEncoding];
    } else if (strcmp(typeEncoding, @encode(long)) == 0) {
        long primitiveValue = [number longValue];
        value = [NSValue value:&primitiveValue withObjCType:typeEncoding];
    } else if (strcmp(typeEncoding, @encode(long long)) == 0) {
        long long primitiveValue = [number longLongValue];
        value = [NSValue value:&primitiveValue withObjCType:typeEncoding];
    } else if (strcmp(typeEncoding, @encode(unsigned char)) == 0) {
        unsigned char primitiveValue = [number unsignedCharValue];
        value = [NSValue value:&primitiveValue withObjCType:typeEncoding];
    } else if (strcmp(typeEncoding, @encode(unsigned int)) == 0) {
        unsigned int primitiveValue = [number unsignedIntValue];
        value = [NSValue value:&primitiveValue withObjCType:typeEncoding];
    } else if (strcmp(typeEncoding, @encode(unsigned short)) == 0) {
        unsigned short primitiveValue = [number unsignedShortValue];
        value = [NSValue value:&primitiveValue withObjCType:typeEncoding];
    } else if (strcmp(typeEncoding, @encode(unsigned long)) == 0) {
        unsigned long primitiveValue = [number unsignedLongValue];
        value = [NSValue value:&primitiveValue withObjCType:typeEncoding];
    } else if (strcmp(typeEncoding, @encode(unsigned long long)) == 0) {
        unsigned long long primitiveValue = [number unsignedLongValue];
        value = [NSValue value:&primitiveValue withObjCType:typeEncoding];
    } else if (strcmp(typeEncoding, @encode(float)) == 0) {
        float primitiveValue = [number floatValue];
        value = [NSValue value:&primitiveValue withObjCType:typeEncoding];
    } else if (strcmp(typeEncoding, @encode(double)) == 0) {
        double primitiveValue = [number doubleValue];
        value = [NSValue value:&primitiveValue withObjCType:typeEncoding];
    }
    
    return value;
}

+ (void)enumerateTypesInStructEncoding:(const char *)structEncoding usingBlock:(void (^)(NSString *structName, const char *fieldTypeEncoding, NSString *prettyTypeEncoding, NSUInteger fieldIndex, NSUInteger fieldOffset))typeBlock
{
    if (structEncoding && structEncoding[0] == '{') {
        const char *equals = strchr(structEncoding, '=');
        if (equals) {
            const char *nameStart = structEncoding + 1;
            NSString *structName = [@(structEncoding) substringWithRange:NSMakeRange(nameStart - structEncoding, equals - nameStart)];
            
            NSUInteger fieldAlignment = 0;
            NSUInteger structSize = 0;
            @try {
                // NSGetSizeAndAlignment barfs on type encoding for bitfields.
                NSGetSizeAndAlignment(structEncoding, &structSize, &fieldAlignment);
            } @catch (NSException *exception) { }
            
            if (structSize > 0) {
                NSUInteger runningFieldIndex = 0;
                NSUInteger runningFieldOffset = 0;
                const char *typeStart = equals + 1;
                while (*typeStart != '}') {
                    NSUInteger fieldSize = 0;
                    // If the struct type encoding was successfully handled by NSGetSizeAndAlignment above, we *should* be ok with the field here.
                    const char *nextTypeStart = NSGetSizeAndAlignment(typeStart, &fieldSize, NULL);
                    NSString *typeEncoding = [@(structEncoding) substringWithRange:NSMakeRange(typeStart - structEncoding, nextTypeStart - typeStart)];
                    typeBlock(structName, [typeEncoding UTF8String], [self readableTypeForEncoding:typeEncoding], runningFieldIndex, runningFieldOffset);
                    runningFieldOffset += fieldSize;
                    // Padding to keep propper alignment. __attribute((packed)) structs will break here.
                    // The type encoding is no different for packed structs, so it's not clear there's anything we can do for those.
                    if (runningFieldOffset % fieldAlignment != 0) {
                        runningFieldOffset += fieldAlignment - runningFieldOffset % fieldAlignment;
                    }
                    runningFieldIndex++;
                    typeStart = nextTypeStart;
                }
            }
        }
    }
}


#pragma mark - Internal Helpers

+ (NSDictionary *)attributesDictionaryForProperty:(objc_property_t)property
{
    NSString *attributes = @(property_getAttributes(property));
    // Thanks to MAObjcRuntime for inspiration here.
    NSArray *attributePairs = [attributes componentsSeparatedByString:@","];
    NSMutableDictionary *attributesDictionary = [NSMutableDictionary dictionaryWithCapacity:[attributePairs count]];
    for (NSString *attributePair in attributePairs) {
        [attributesDictionary setObject:[attributePair substringFromIndex:1] forKey:[attributePair substringToIndex:1]];
    }
    return attributesDictionary;
}

+ (NSString *)appendName:(NSString *)name toType:(NSString *)type
{
    NSString *combined = nil;
    if ([type characterAtIndex:[type length] - 1] == '*') {
        combined = [type stringByAppendingString:name];
    } else {
        combined = [type stringByAppendingFormat:@" %@", name];
    }
    return combined;
}

+ (NSString *)readableTypeForEncoding:(NSString *)encodingString
{
    if (!encodingString) {
        return nil;
    }
    
    // See https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
    // class-dump has a much nicer and much more complete implementation for this task, but it is distributed under GPLv2 :/
    // See https://github.com/nygard/class-dump/blob/master/Source/CDType.m
    // Warning: this method uses multiple middle returns and macros to cut down on boilerplate.
    // The use of macros here was inspired by https://www.mikeash.com/pyblog/friday-qa-2013-02-08-lets-build-key-value-coding.html
    const char *encodingCString = [encodingString UTF8String];
    
    // Objects
    if (encodingCString[0] == '@') {
        NSString *class = [encodingString substringFromIndex:1];
        class = [class stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        if ([class length] == 0 || [class isEqual:@"?"]) {
            class = @"id";
        } else {
            class = [class stringByAppendingString:@" *"];
        }
        return class;
    }
    
    // C Types
#define TRANSLATE(ctype) \
    if (strcmp(encodingCString, @encode(ctype)) == 0) { \
        return (NSString *)CFSTR(#ctype); \
    }
    
    // Order matters here since some of the cocoa types are typedefed to c types.
    // We can't recover the exact mapping, but we choose to prefer the cocoa types.
    // This is not an exhaustive list, but it covers the most common types
    TRANSLATE(CGRect);
    TRANSLATE(CGPoint);
    TRANSLATE(CGSize);
    TRANSLATE(UIEdgeInsets);
    TRANSLATE(UIOffset);
    TRANSLATE(NSRange);
    TRANSLATE(CGAffineTransform);
    TRANSLATE(CATransform3D);
    TRANSLATE(CGColorRef);
    TRANSLATE(CGPathRef);
    TRANSLATE(CGContextRef);
    TRANSLATE(NSInteger);
    TRANSLATE(NSUInteger);
    TRANSLATE(CGFloat);
    TRANSLATE(BOOL);
    TRANSLATE(int);
    TRANSLATE(short);
    TRANSLATE(long);
    TRANSLATE(long long);
    TRANSLATE(unsigned char);
    TRANSLATE(unsigned int);
    TRANSLATE(unsigned short);
    TRANSLATE(unsigned long);
    TRANSLATE(unsigned long long);
    TRANSLATE(float);
    TRANSLATE(double);
    TRANSLATE(long double);
    TRANSLATE(char *);
    TRANSLATE(Class);
    TRANSLATE(objc_property_t);
    TRANSLATE(Ivar);
    TRANSLATE(Method);
    TRANSLATE(Category);
    TRANSLATE(NSZone *);
    TRANSLATE(SEL);
    TRANSLATE(void);
    
#undef TRANSLATE
    
    // Qualifier Prefixes
    // Do this after the checks above since some of the direct translations (i.e. Method) contain a prefix.
#define RECURSIVE_TRANSLATE(prefix, formatString) \
    if (encodingCString[0] == prefix) { \
        NSString *recursiveType = [self readableTypeForEncoding:[encodingString substringFromIndex:1]]; \
        return [NSString stringWithFormat:formatString, recursiveType]; \
    }
    
    // If there's a qualifier prefix on the encoding, translate it and then
    // recursively call this method with the rest of the encoding string.
    RECURSIVE_TRANSLATE('^', @"%@ *");
    RECURSIVE_TRANSLATE('r', @"const %@");
    RECURSIVE_TRANSLATE('n', @"in %@");
    RECURSIVE_TRANSLATE('N', @"inout %@");
    RECURSIVE_TRANSLATE('o', @"out %@");
    RECURSIVE_TRANSLATE('O', @"bycopy %@");
    RECURSIVE_TRANSLATE('R', @"byref %@");
    RECURSIVE_TRANSLATE('V', @"oneway %@");
    RECURSIVE_TRANSLATE('b', @"bitfield(%@)");
    
#undef RECURSIVE_TRANSLATE
    
    // If we couldn't translate, just return the original encoding string
    return encodingString;
}

+ (NSValue *)valueForPrimitivePointer:(void *)pointer objCType:(const char *)type
{
    // CASE macro inspired by https://www.mikeash.com/pyblog/friday-qa-2013-02-08-lets-build-key-value-coding.html
#define CASE(ctype, selectorpart) \
    if(strcmp(type, @encode(ctype)) == 0) { \
        return [NSNumber numberWith ## selectorpart: *(ctype *)pointer]; \
    }
    
    CASE(BOOL, Bool);
    CASE(unsigned char, UnsignedChar);
    CASE(short, Short);
    CASE(unsigned short, UnsignedShort);
    CASE(int, Int);
    CASE(unsigned int, UnsignedInt);
    CASE(long, Long);
    CASE(unsigned long, UnsignedLong);
    CASE(long long, LongLong);
    CASE(unsigned long long, UnsignedLongLong);
    CASE(float, Float);
    CASE(double, Double);
    
#undef CASE
    
    NSValue *value = nil;
    @try {
        value = [NSValue valueWithBytes:pointer objCType:type];
    } @catch (NSException *exception) {
        // Certain type encodings are not supported by valueWithBytes:objCType:. Just fail silently if an exception is thrown.
    }
    
    return value;
}

@end
