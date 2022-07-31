//
//  FLEXRuntimeUtility.m
//  Flipboard
//
//  Created by Ryan Olson on 6/8/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FLEXRuntimeUtility.h"
#import "FLEXObjcInternal.h"
#import "FLEXTypeEncodingParser.h"
#import "FLEXMethod.h"

NSString * const FLEXRuntimeUtilityErrorDomain = @"FLEXRuntimeUtilityErrorDomain";

@implementation FLEXRuntimeUtility

#pragma mark - General Helpers (Public)

+ (BOOL)pointerIsValidObjcObject:(const void *)pointer {
    return FLEXPointerIsValidObjcObject(pointer);
}

+ (id)potentiallyUnwrapBoxedPointer:(id)returnedObjectOrNil type:(const FLEXTypeEncoding *)returnType {
    if (!returnedObjectOrNil) {
        return nil;
    }

    NSInteger i = 0;
    if (returnType[i] == FLEXTypeEncodingConst) {
        i++;
    }

    BOOL returnsObjectOrClass = returnType[i] == FLEXTypeEncodingObjcObject ||
                                returnType[i] == FLEXTypeEncodingObjcClass;
    BOOL returnsVoidPointer   = returnType[i] == FLEXTypeEncodingPointer &&
                                returnType[i+1] == FLEXTypeEncodingVoid;
    BOOL returnsCString       = returnType[i] == FLEXTypeEncodingCString;

    // If we got back an NSValue and the return type is not an object,
    // we check to see if the pointer is of a valid object. If not,
    // we just display the NSValue.
    if (!returnsObjectOrClass) {
        // Skip NSNumber instances
        if ([returnedObjectOrNil isKindOfClass:[NSNumber class]]) {
            return returnedObjectOrNil;
        }
        
        // Can only be NSValue since return type is not an object,
        // so we bail if this doesn't add up
        if (![returnedObjectOrNil isKindOfClass:[NSValue class]]) {
            return returnedObjectOrNil;
        }

        NSValue *value = (NSValue *)returnedObjectOrNil;

        if (returnsCString) {
            // Wrap char * in NSString
            const char *string = (const char *)value.pointerValue;
            returnedObjectOrNil = string ? [NSString stringWithCString:string encoding:NSUTF8StringEncoding] : NULL;
        } else if (returnsVoidPointer) {
            // Cast valid objects disguised as void * to id
            if ([FLEXRuntimeUtility pointerIsValidObjcObject:value.pointerValue]) {
                returnedObjectOrNil = (__bridge id)value.pointerValue;
            }
        }
    }

    return returnedObjectOrNil;
}

+ (NSUInteger)fieldNameOffsetForTypeEncoding:(const FLEXTypeEncoding *)typeEncoding {
    NSUInteger beginIndex = 0;
    while (typeEncoding[beginIndex] == FLEXTypeEncodingQuote) {
        NSUInteger endIndex = beginIndex + 1;
        while (typeEncoding[endIndex] != FLEXTypeEncodingQuote) {
            ++endIndex;
        }
        beginIndex = endIndex + 1;
    }
    return beginIndex;
}

+ (NSArray<Class> *)classHierarchyOfObject:(id)objectOrClass {
    NSMutableArray<Class> *superClasses = [NSMutableArray new];
    id cls = [objectOrClass class];
    do {
        [superClasses addObject:cls];
    } while ((cls = [cls superclass]));

    return superClasses;
}

+ (NSString *)safeClassNameForObject:(id)object {
    // Don't assume that we have an NSObject subclass
    if ([self safeObject:object respondsToSelector:@selector(class)]) {
        return NSStringFromClass([object class]);
    }

    return NSStringFromClass(object_getClass(object));
}

/// Could be nil
+ (NSString *)safeDescriptionForObject:(id)object {
    // Don't assume that we have an NSObject subclass; not all objects respond to -description
    if ([self safeObject:object respondsToSelector:@selector(description)]) {
        @try {
            return [object description];
        } @catch (NSException *exception) {
            return nil;
        }
    }

    return nil;
}

/// Never nil
+ (NSString *)safeDebugDescriptionForObject:(id)object {
    NSString *description = nil;

    if ([self safeObject:object respondsToSelector:@selector(debugDescription)]) {
        @try {
            description = [object debugDescription];
        } @catch (NSException *exception) { }
    } else {
        description = [self safeDescriptionForObject:object];
    }

    if (!description.length) {
        NSString *cls = NSStringFromClass(object_getClass(object));
        if (object_isClass(object)) {
            description = [cls stringByAppendingString:@" class (no description)"];
        } else {
            description = [cls stringByAppendingString:@" instance (no description)"];
        }
    }

    return description;
}

+ (NSString *)summaryForObject:(id)value {
    NSString *description = nil;

    // Special case BOOL for better readability.
    if ([self safeObject:value isKindOfClass:[NSValue class]]) {
        const char *type = [value objCType];
        if (strcmp(type, @encode(BOOL)) == 0) {
            BOOL boolValue = NO;
            [value getValue:&boolValue];
            return boolValue ? @"YES" : @"NO";
        } else if (strcmp(type, @encode(SEL)) == 0) {
            SEL selector = NULL;
            [value getValue:&selector];
            return NSStringFromSelector(selector);
        }
    }

    @try {
        // Single line display - replace newlines and tabs with spaces.
        description = [[self safeDescriptionForObject:value] stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        description = [description stringByReplacingOccurrencesOfString:@"\t" withString:@" "];
        description = [description stringByReplacingOccurrencesOfString:@"    " withString:@" "];
    } @catch (NSException *e) {
        description = [@"Thrown: " stringByAppendingString:e.reason ?: @"(nil exception reason)"];
    }

    if (!description) {
        description = @"nil";
    }

    return description;
}

+ (BOOL)safeObject:(id)object isKindOfClass:(Class)cls {
    static BOOL (*isKindOfClass)(id, SEL, Class) = nil;
    static BOOL (*isKindOfClass_meta)(id, SEL, Class) = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        isKindOfClass = (BOOL(*)(id, SEL, Class))[NSObject instanceMethodForSelector:@selector(isKindOfClass:)];
        isKindOfClass_meta = (BOOL(*)(id, SEL, Class))[NSObject methodForSelector:@selector(isKindOfClass:)];
    });
    
    BOOL isClass = object_isClass(object);
    return (isClass ? isKindOfClass_meta : isKindOfClass)(object, @selector(isKindOfClass:), cls);
}

+ (BOOL)safeObject:(id)object respondsToSelector:(SEL)sel {
    // If we're given a class, we want to know if classes respond to this selector.
    // Similarly, if we're given an instance, we want to know if instances respond. 
    BOOL isClass = object_isClass(object);
    Class cls = isClass ? object : object_getClass(object);
    // BOOL isMetaclass = class_isMetaClass(cls);
    
    if (isClass) {
        // In theory, this should also work for metaclasses...
        return class_getClassMethod(cls, sel) != nil;
    } else {
        return class_getInstanceMethod(cls, sel) != nil;
    }
}


#pragma mark - Property Helpers (Public)

+ (BOOL)tryAddPropertyWithName:(const char *)name
                    attributes:(NSDictionary<NSString *, NSString *> *)attributePairs
                       toClass:(__unsafe_unretained Class)theClass {
    objc_property_t property = class_getProperty(theClass, name);
    if (!property) {
        unsigned int totalAttributesCount = (unsigned int)attributePairs.count;
        objc_property_attribute_t *attributes = malloc(sizeof(objc_property_attribute_t) * totalAttributesCount);
        if (attributes) {
            unsigned int attributeIndex = 0;
            for (NSString *attributeName in attributePairs.allKeys) {
                objc_property_attribute_t attribute;
                attribute.name = attributeName.UTF8String;
                attribute.value = attributePairs[attributeName].UTF8String;
                attributes[attributeIndex++] = attribute;
            }

            BOOL success = class_addProperty(theClass, name, attributes, totalAttributesCount);
            free(attributes);
            return success;
        } else {
            return NO;
        }
    }
    
    return YES;
}

+ (NSArray<NSString *> *)allPropertyAttributeKeys {
    static NSArray<NSString *> *allPropertyAttributeKeys = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        allPropertyAttributeKeys = @[
            kFLEXPropertyAttributeKeyTypeEncoding,
            kFLEXPropertyAttributeKeyBackingIvarName,
            kFLEXPropertyAttributeKeyReadOnly,
            kFLEXPropertyAttributeKeyCopy,
            kFLEXPropertyAttributeKeyRetain,
            kFLEXPropertyAttributeKeyNonAtomic,
            kFLEXPropertyAttributeKeyCustomGetter,
            kFLEXPropertyAttributeKeyCustomSetter,
            kFLEXPropertyAttributeKeyDynamic,
            kFLEXPropertyAttributeKeyWeak,
            kFLEXPropertyAttributeKeyGarbageCollectable,
            kFLEXPropertyAttributeKeyOldStyleTypeEncoding,
        ];
    });

    return allPropertyAttributeKeys;
}


#pragma mark - Method Helpers (Public)

+ (NSArray<NSString *> *)prettyArgumentComponentsForMethod:(Method)method {
    NSMutableArray<NSString *> *components = [NSMutableArray new];

    NSString *selectorName = NSStringFromSelector(method_getName(method));
    NSMutableArray<NSString *> *selectorComponents = [selectorName componentsSeparatedByString:@":"].mutableCopy;

    // this is a workaround cause method_getNumberOfArguments() returns wrong number for some methods
    if (selectorComponents.count == 1) {
        return @[];
    }

    if ([selectorComponents.lastObject isEqualToString:@""]) {
        [selectorComponents removeLastObject];
    }

    for (unsigned int argIndex = 0; argIndex < selectorComponents.count; argIndex++) {
        char *argType = method_copyArgumentType(method, argIndex + kFLEXNumberOfImplicitArgs);
        NSString *readableArgType = (argType != NULL) ? [self readableTypeForEncoding:@(argType)] : nil;
        free(argType);
        NSString *prettyComponent = [NSString
            stringWithFormat:@"%@:(%@) ",
            selectorComponents[argIndex],
            readableArgType
        ];
        [components addObject:prettyComponent];
    }

    return components;
}


#pragma mark - Method Calling/Field Editing (Public)

+ (id)performSelector:(SEL)selector onObject:(id)object {
    return [self performSelector:selector onObject:object withArguments:@[] error:nil];
}

+ (id)performSelector:(SEL)selector
             onObject:(id)object
        withArguments:(NSArray *)arguments
                error:(NSError * __autoreleasing *)error {
    return [self performSelector:selector
        onObject:object
        withArguments:arguments
        allowForwarding:NO
        error:error
    ];
}

+ (id)performSelector:(SEL)selector
             onObject:(id)object
        withArguments:(NSArray *)arguments
      allowForwarding:(BOOL)mightForwardMsgSend
                error:(NSError * __autoreleasing *)error {
    static dispatch_once_t onceToken;
    static SEL stdStringExclusion = nil;
    dispatch_once(&onceToken, ^{
        stdStringExclusion = NSSelectorFromString(@"stdString");
    });

    // Bail if the object won't respond to this selector
    if (mightForwardMsgSend || ![self safeObject:object respondsToSelector:selector]) {
        if (error) {
            NSString *msg = [NSString
                stringWithFormat:@"This object does not respond to the selector %@",
                NSStringFromSelector(selector)
            ];
            NSDictionary<NSString *, id> *userInfo = @{ NSLocalizedDescriptionKey : msg };
            *error = [NSError
                errorWithDomain:FLEXRuntimeUtilityErrorDomain
                code:FLEXRuntimeUtilityErrorCodeDoesNotRecognizeSelector
                userInfo:userInfo
            ];
        }

        return nil;
    }

    // It is important to use object_getClass and not -class here, as
    // object_getClass will return a different result for class objects
    Class cls = object_getClass(object);
    NSMethodSignature *methodSignature = [FLEXMethod selector:selector class:cls].signature;
    if (!methodSignature) {
        // Unsupported type encoding
        return nil;
    }
    
    // Probably an unsupported type encoding, like bitfields.
    // In the future, we could calculate the return length
    // on our own. For now, we abort.
    //
    // For future reference, the code here will get the true type encoding.
    // NSMethodSignature will convert {?=b8b4b1b1b18[8S]} to {?}
    //
    // returnType = method_getTypeEncoding(class_getInstanceMethod([object class], selector));
    if (!methodSignature.methodReturnLength &&
        methodSignature.methodReturnType[0] != FLEXTypeEncodingVoid) {
        return nil;
    }

    // Build the invocation
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    [invocation setSelector:selector];
    [invocation setTarget:object];
    [invocation retainArguments];

    // Always self and _cmd
    NSUInteger numberOfArguments = methodSignature.numberOfArguments;
    for (NSUInteger argumentIndex = kFLEXNumberOfImplicitArgs; argumentIndex < numberOfArguments; argumentIndex++) {
        NSUInteger argumentsArrayIndex = argumentIndex - kFLEXNumberOfImplicitArgs;
        id argumentObject = arguments.count > argumentsArrayIndex ? arguments[argumentsArrayIndex] : nil;

        // NSNull in the arguments array can be passed as a placeholder to indicate nil.
        // We only need to set the argument if it will be non-nil.
        if (argumentObject && ![argumentObject isKindOfClass:[NSNull class]]) {
            const char *typeEncodingCString = [methodSignature getArgumentTypeAtIndex:argumentIndex];
            if (typeEncodingCString[0] == FLEXTypeEncodingObjcObject ||
              typeEncodingCString[0] == FLEXTypeEncodingObjcClass ||
              [self isTollFreeBridgedValue:argumentObject forCFType:typeEncodingCString]) {
                // Object
                [invocation setArgument:&argumentObject atIndex:argumentIndex];
            } else if (strcmp(typeEncodingCString, @encode(CGColorRef)) == 0 &&
                    [argumentObject isKindOfClass:[UIColor class]]) {
                // Bridging UIColor to CGColorRef
                CGColorRef colorRef = [argumentObject CGColor];
                [invocation setArgument:&colorRef atIndex:argumentIndex];
            } else if ([argumentObject isKindOfClass:[NSValue class]]) {
                // Primitive boxed in NSValue
                NSValue *argumentValue = (NSValue *)argumentObject;

                // Ensure that the type encoding on the NSValue matches the type encoding of the argument in the method signature
                if (strcmp([argumentValue objCType], typeEncodingCString) != 0) {
                    if (error) {
                        NSString *msg =  [NSString
                            stringWithFormat:@"Type encoding mismatch for argument at index %lu. "
                            "Value type: %s; Method argument type: %s.",
                            (unsigned long)argumentsArrayIndex, argumentValue.objCType, typeEncodingCString
                        ];
                        NSDictionary<NSString *, id> *userInfo = @{ NSLocalizedDescriptionKey : msg };
                        *error = [NSError
                            errorWithDomain:FLEXRuntimeUtilityErrorDomain
                            code:FLEXRuntimeUtilityErrorCodeArgumentTypeMismatch
                            userInfo:userInfo
                        ];
                    }
                    return nil;
                }

                @try {
                    NSUInteger bufferSize = 0;
                    FLEXGetSizeAndAlignment(typeEncodingCString, &bufferSize, NULL);

                    if (bufferSize > 0) {
                        void *buffer = alloca(bufferSize);
                        [argumentValue getValue:buffer];
                        [invocation setArgument:buffer atIndex:argumentIndex];
                    }
                } @catch (NSException *exception) { }
            }
        }
    }

    // Try to invoke the invocation but guard against an exception being thrown.
    id returnObject = nil;
    @try {
        [invocation invoke];

        // Retrieve the return value and box if necessary.
        const char *returnType = methodSignature.methodReturnType;

        if (returnType[0] == FLEXTypeEncodingObjcObject || returnType[0] == FLEXTypeEncodingObjcClass) {
            // Return value is an object.
            __unsafe_unretained id objectReturnedFromMethod = nil;
            [invocation getReturnValue:&objectReturnedFromMethod];
            returnObject = objectReturnedFromMethod;
        } else if (returnType[0] != FLEXTypeEncodingVoid) {
            NSAssert(methodSignature.methodReturnLength, @"Memory corruption lies ahead");

            if (returnType[0] == FLEXTypeEncodingStructBegin) {
                if (selector == stdStringExclusion && [object isKindOfClass:[NSString class]]) {
                    // stdString is a C++ object and we will crash if we try to access it
                    if (error) {
                        *error = [NSError
                            errorWithDomain:FLEXRuntimeUtilityErrorDomain
                            code:FLEXRuntimeUtilityErrorCodeInvocationFailed
                            userInfo:@{ NSLocalizedDescriptionKey : @"Skipping -[NSString stdString]" }
                        ];
                    }

                    return nil;
                }
            }

            // Will use arbitrary buffer for return value and box it.
            void *returnValue = malloc(methodSignature.methodReturnLength);
            [invocation getReturnValue:returnValue];
            returnObject = [self valueForPrimitivePointer:returnValue objCType:returnType];
            free(returnValue);
        }
    } @catch (NSException *exception) {
        // Bummer...
        if (error) {
            // "… on <class>" / "… on instance of <class>"
            NSString *class = NSStringFromClass([object class]);
            NSString *calledOn = object == [object class] ? class : [@"an instance of " stringByAppendingString:class];

            NSString *message = [NSString
                stringWithFormat:@"Exception '%@' thrown while performing selector '%@' on %@.\nReason:\n\n%@",
                exception.name, NSStringFromSelector(selector), calledOn, exception.reason
            ];

            *error = [NSError
                errorWithDomain:FLEXRuntimeUtilityErrorDomain
                code:FLEXRuntimeUtilityErrorCodeInvocationFailed
                userInfo:@{ NSLocalizedDescriptionKey : message }
            ];
        }
    }

    return returnObject;
}

+ (BOOL)isTollFreeBridgedValue:(id)value forCFType:(const char *)typeEncoding {
    // See https://developer.apple.com/library/archive/documentation/General/Conceptual/CocoaEncyclopedia/Toll-FreeBridgin/Toll-FreeBridgin.html
#define CASE(cftype, foundationClass) \
    if (strcmp(typeEncoding, @encode(cftype)) == 0) { \
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

+ (NSString *)editableJSONStringForObject:(id)object {
    NSString *editableDescription = nil;

    if (object) {
        // This is a hack to use JSON serialization for our editable objects.
        // NSJSONSerialization doesn't allow writing fragments - the top level object must be an array or dictionary.
        // We always wrap the object inside an array and then strip the outer square braces off the final string.
        NSArray *wrappedObject = @[object];
        if ([NSJSONSerialization isValidJSONObject:wrappedObject]) {
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:wrappedObject options:0 error:NULL];
            NSString *wrappedDescription = [NSString stringWithUTF8String:jsonData.bytes];
            editableDescription = [wrappedDescription substringWithRange:NSMakeRange(1, wrappedDescription.length - 2)];
        }
    }

    return editableDescription;
}

+ (id)objectValueFromEditableJSONString:(NSString *)string {
    id value = nil;
    // nil for empty string/whitespace
    if ([string stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].length) {
        value = [NSJSONSerialization
            JSONObjectWithData:[string dataUsingEncoding:NSUTF8StringEncoding]
            options:NSJSONReadingAllowFragments
            error:NULL
        ];
    }
    return value;
}

+ (NSValue *)valueForNumberWithObjCType:(const char *)typeEncoding fromInputString:(NSString *)inputString {
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    NSNumber *number = [formatter numberFromString:inputString];
    
    // Is the type encoding longer than one character?
    if (strlen(typeEncoding) > 1) {
        NSString *type = @(typeEncoding);
        
        // Is it NSDecimalNumber or NSNumber?
        if ([type isEqualToString:@FLEXEncodeClass(NSDecimalNumber)]) {
            return [NSDecimalNumber decimalNumberWithString:inputString];
        } else if ([type isEqualToString:@FLEXEncodeClass(NSNumber)]) {
            return number;
        }
        
        return nil;
    }
    
    // Type encoding is one character, switch on the type
    FLEXTypeEncoding type = typeEncoding[0];
    uint8_t value[32];
    void *bufferStart = &value[0];
    
    // Make sure we box the number with the correct type encoding
    // so it can be properly unboxed later via getValue:
    switch (type) {
        case FLEXTypeEncodingChar:
            *(char *)bufferStart = number.charValue; break;
        case FLEXTypeEncodingInt:
            *(int *)bufferStart = number.intValue; break;
        case FLEXTypeEncodingShort:
            *(short *)bufferStart = number.shortValue; break;
        case FLEXTypeEncodingLong:
            *(long *)bufferStart = number.longValue; break;
        case FLEXTypeEncodingLongLong:
            *(long long *)bufferStart = number.longLongValue; break;
        case FLEXTypeEncodingUnsignedChar:
            *(unsigned char *)bufferStart = number.unsignedCharValue; break;
        case FLEXTypeEncodingUnsignedInt:
            *(unsigned int *)bufferStart = number.unsignedIntValue; break;
        case FLEXTypeEncodingUnsignedShort:
            *(unsigned short *)bufferStart = number.unsignedShortValue; break;
        case FLEXTypeEncodingUnsignedLong:
            *(unsigned long *)bufferStart = number.unsignedLongValue; break;
        case FLEXTypeEncodingUnsignedLongLong:
            *(unsigned long long *)bufferStart = number.unsignedLongLongValue; break;
        case FLEXTypeEncodingFloat:
            *(float *)bufferStart = number.floatValue; break;
        case FLEXTypeEncodingDouble:
            *(double *)bufferStart = number.doubleValue; break;
            
        case FLEXTypeEncodingLongDouble:
            // NSNumber does not support long double
        default:
            return nil;
    }
    
    return [NSValue value:value withObjCType:typeEncoding];
}

+ (void)enumerateTypesInStructEncoding:(const char *)structEncoding
                            usingBlock:(void (^)(NSString *structName,
                                                 const char *fieldTypeEncoding,
                                                 NSString *prettyTypeEncoding,
                                                 NSUInteger fieldIndex,
                                                 NSUInteger fieldOffset))typeBlock {
    if (structEncoding && structEncoding[0] == FLEXTypeEncodingStructBegin) {
        const char *equals = strchr(structEncoding, '=');
        if (equals) {
            const char *nameStart = structEncoding + 1;
            NSString *structName = [@(structEncoding)
                substringWithRange:NSMakeRange(nameStart - structEncoding, equals - nameStart)
            ];

            NSUInteger fieldAlignment = 0, structSize = 0;
            if (FLEXGetSizeAndAlignment(structEncoding, &structSize, &fieldAlignment)) {
                NSUInteger runningFieldIndex = 0;
                NSUInteger runningFieldOffset = 0;
                const char *typeStart = equals + 1;
                
                while (*typeStart != FLEXTypeEncodingStructEnd) {
                    NSUInteger fieldSize = 0;
                    // If the struct type encoding was successfully handled by
                    // FLEXGetSizeAndAlignment above, we *should* be ok with the field here.
                    const char *nextTypeStart = NSGetSizeAndAlignment(typeStart, &fieldSize, NULL);
                    NSString *typeEncoding = [@(structEncoding)
                        substringWithRange:NSMakeRange(typeStart - structEncoding, nextTypeStart - typeStart)
                    ];
                    
                    // Padding to keep proper alignment. __attribute((packed)) structs
                    // will break here. The type encoding is no different for packed structs,
                    // so it's not clear there's anything we can do for those.
                    const NSUInteger currentSizeSum = runningFieldOffset % fieldAlignment;
                    if (currentSizeSum != 0 && currentSizeSum + fieldSize > fieldAlignment) {
                        runningFieldOffset += fieldAlignment - currentSizeSum;
                    }
                    
                    typeBlock(
                        structName,
                        typeEncoding.UTF8String,
                        [self readableTypeForEncoding:typeEncoding],
                        runningFieldIndex,
                        runningFieldOffset
                    );
                    runningFieldOffset += fieldSize;
                    runningFieldIndex++;
                    typeStart = nextTypeStart;
                }
            }
        }
    }
}


#pragma mark - Metadata Helpers

+ (NSDictionary<NSString *, NSString *> *)attributesForProperty:(objc_property_t)property {
    NSString *attributes = @(property_getAttributes(property) ?: "");
    // Thanks to MAObjcRuntime for inspiration here.
    NSArray<NSString *> *attributePairs = [attributes componentsSeparatedByString:@","];
    NSMutableDictionary<NSString *, NSString *> *attributesDictionary = [NSMutableDictionary new];
    for (NSString *attributePair in attributePairs) {
        attributesDictionary[[attributePair substringToIndex:1]] = [attributePair substringFromIndex:1];
    }
    return attributesDictionary;
}

+ (NSString *)appendName:(NSString *)name toType:(NSString *)type {
    if (!type.length) {
        type = @"(?)";
    }
    
    NSString *combined = nil;
    if ([type characterAtIndex:type.length - 1] == FLEXTypeEncodingCString) {
        combined = [type stringByAppendingString:name];
    } else {
        combined = [type stringByAppendingFormat:@" %@", name];
    }
    return combined;
}

+ (NSString *)readableTypeForEncoding:(NSString *)encodingString {
    if (!encodingString.length) {
        return @"?";
    }

    // See https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
    // class-dump has a much nicer and much more complete implementation for this task, but it is distributed under GPLv2 :/
    // See https://github.com/nygard/class-dump/blob/master/Source/CDType.m
    // Warning: this method uses multiple middle returns and macros to cut down on boilerplate.
    // The use of macros here was inspired by https://www.mikeash.com/pyblog/friday-qa-2013-02-08-lets-build-key-value-coding.html
    const char *encodingCString = encodingString.UTF8String;

    // Some fields have a name, such as {Size=\"width\"d\"height\"d}, we need to extract the name out and recursive
    const NSUInteger fieldNameOffset = [FLEXRuntimeUtility fieldNameOffsetForTypeEncoding:encodingCString];
    if (fieldNameOffset > 0) {
        // According to https://github.com/nygard/class-dump/commit/33fb5ed221810685f57c192e1ce8ab6054949a7c,
        // there are some consecutive quoted strings, so use `_` to concatenate the names.
        NSString *const fieldNamesString = [encodingString substringWithRange:NSMakeRange(0, fieldNameOffset)];
        NSArray<NSString *> *const fieldNames = [fieldNamesString
            componentsSeparatedByString:[NSString stringWithFormat:@"%c", FLEXTypeEncodingQuote]
        ];
        NSMutableString *finalFieldNamesString = [NSMutableString new];
        for (NSString *const fieldName in fieldNames) {
            if (fieldName.length > 0) {
                if (finalFieldNamesString.length > 0) {
                    [finalFieldNamesString appendString:@"_"];
                }
                [finalFieldNamesString appendString:fieldName];
            }
        }
        NSString *const recursiveType = [self readableTypeForEncoding:[encodingString substringFromIndex:fieldNameOffset]];
        return [NSString stringWithFormat:@"%@ %@", recursiveType, finalFieldNamesString];
    }

    // Objects
    if (encodingCString[0] == FLEXTypeEncodingObjcObject) {
        NSString *class = [encodingString substringFromIndex:1];
        class = [class stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        if (class.length == 0 || (class.length == 1 && [class characterAtIndex:0] == FLEXTypeEncodingUnknown)) {
            class = @"id";
        } else {
            class = [class stringByAppendingString:@" *"];
        }
        return class;
    }

    // Qualifier Prefixes
    // Do this first since some of the direct translations (i.e. Method) contain a prefix.
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
    TRANSLATE(CGVector);
    TRANSLATE(UIEdgeInsets);
    if (@available(iOS 11.0, *)) {
      TRANSLATE(NSDirectionalEdgeInsets);
    }
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

    // For structs, we only use the name of the structs
    if (encodingCString[0] == FLEXTypeEncodingStructBegin) {
        // Special case: std::string
        if ([encodingString hasPrefix:@"{basic_string<char"]) {
            return @"std::string";
        }

        const char *equals = strchr(encodingCString, '=');
        if (equals) {
            const char *nameStart = encodingCString + 1;
            // For anonymous structs
            if (nameStart[0] == FLEXTypeEncodingUnknown) {
                return @"anonymous struct";
            } else {
                NSString *const structName = [encodingString
                    substringWithRange:NSMakeRange(nameStart - encodingCString, equals - nameStart)
                ];
                return structName;
            }
        }
    }

    // If we couldn't translate, just return the original encoding string
    return encodingString;
}


#pragma mark - Internal Helpers

+ (NSValue *)valueForPrimitivePointer:(void *)pointer objCType:(const char *)type {
    // Remove the field name if there is any (e.g. \"width\"d -> d)
    const NSUInteger fieldNameOffset = [FLEXRuntimeUtility fieldNameOffsetForTypeEncoding:type];
    if (fieldNameOffset > 0) {
        return [self valueForPrimitivePointer:pointer objCType:type + fieldNameOffset];
    }

    // CASE macro inspired by https://www.mikeash.com/pyblog/friday-qa-2013-02-08-lets-build-key-value-coding.html
#define CASE(ctype, selectorpart) \
    if (strcmp(type, @encode(ctype)) == 0) { \
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
    CASE(long double, Double);

#undef CASE

    NSValue *value = nil;
    if (FLEXGetSizeAndAlignment(type, nil, nil)) {
        @try {
            value = [NSValue valueWithBytes:pointer objCType:type];
        } @catch (NSException *exception) {
            // Certain type encodings are not supported by valueWithBytes:objCType:.
            // Just fail silently if an exception is thrown.
        }
    }

    return value;
}

@end
