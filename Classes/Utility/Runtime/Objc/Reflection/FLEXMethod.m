//
//  FLEXMethod.m
//  FLEX
//
//  Derived from MirrorKit.
//  Created by Tanner on 6/30/15.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXMethod.h"
#import "FLEXMirror.h"
#import "FLEXTypeEncodingParser.h"
#import "FLEXRuntimeUtility.h"
#include <dlfcn.h>

@implementation FLEXMethod
@synthesize imagePath = _imagePath;
@dynamic implementation;

+ (instancetype)buildMethodNamed:(NSString *)name withTypes:(NSString *)typeEncoding implementation:(IMP)implementation {
    [NSException raise:NSInternalInconsistencyException format:@"Class instance should not be created with +buildMethodNamed:withTypes:implementation"]; return nil;
}

- (id)init {
    [NSException
        raise:NSInternalInconsistencyException
        format:@"Class instance should not be created with -init"
    ];
    return nil;
}

#pragma mark Initializers

+ (instancetype)method:(Method)method {
    return [[self alloc] initWithMethod:method isInstanceMethod:YES];
}

+ (instancetype)method:(Method)method isInstanceMethod:(BOOL)isInstanceMethod {
    return [[self alloc] initWithMethod:method isInstanceMethod:isInstanceMethod];
}

+ (instancetype)selector:(SEL)selector class:(Class)cls {
    BOOL instance = !class_isMetaClass(cls);
    // class_getInstanceMethod will return an instance method if not given
    // not given a metaclass, or a class method if given a metaclass, but
    // this isn't documented so we just want to be safe here.
    Method m = instance ? class_getInstanceMethod(cls, selector) : class_getClassMethod(cls, selector);
    if (m == NULL) return nil;
    
    return [self method:m isInstanceMethod:instance];
}

+ (instancetype)selector:(SEL)selector implementedInClass:(Class)cls {
    if (![cls superclass]) { return [self selector:selector class:cls]; }
    
    BOOL unique = [cls methodForSelector:selector] != [[cls superclass] methodForSelector:selector];
    
    if (unique) {
        return [self selector:selector class:cls];
    }
    
    return nil;
}

- (id)initWithMethod:(Method)method isInstanceMethod:(BOOL)isInstanceMethod {
    NSParameterAssert(method);
    
    self = [super init];
    if (self) {
        _objc_method = method;
        _isInstanceMethod = isInstanceMethod;
        _signatureString = @(method_getTypeEncoding(method) ?: "?@:");
        
        NSString *cleanSig = nil;
        if ([FLEXTypeEncodingParser methodTypeEncodingSupported:_signatureString cleaned:&cleanSig]) {
            _signature = [NSMethodSignature signatureWithObjCTypes:cleanSig.UTF8String];
        }

        [self examine];
    }
    
    return self;
}


#pragma mark Other

- (NSString *)description {
    if (!_flex_description) {
        _flex_description = [self prettyName];
    }
    
    return _flex_description;
}

- (NSString *)debugNameGivenClassName:(NSString *)name {
    NSMutableString *string = [NSMutableString stringWithString:_isInstanceMethod ? @"-[" : @"+["];
    [string appendString:name];
    [string appendString:@" "];
    [string appendString:self.selectorString];
    [string appendString:@"]"];
    return string;
}

- (NSString *)prettyName {
    NSString *methodTypeString = self.isInstanceMethod ? @"-" : @"+";
    NSString *readableReturnType = [FLEXRuntimeUtility readableTypeForEncoding:@(self.signature.methodReturnType ?: "")];
    
    NSString *prettyName = [NSString stringWithFormat:@"%@ (%@)", methodTypeString, readableReturnType];
    NSArray *components = [self prettyArgumentComponents];

    if (components.count) {
        return [prettyName stringByAppendingString:[components componentsJoinedByString:@" "]];
    } else {
        return [prettyName stringByAppendingString:self.selectorString];
    }
}

- (NSArray *)prettyArgumentComponents {
    // NSMethodSignature can't handle some type encodings
    // like ^AI@:ir* which happen to very much exist
    if (self.signature.numberOfArguments < self.numberOfArguments) {
        return nil;
    }
    
    NSMutableArray *components = [NSMutableArray new];

    NSArray *selectorComponents = [self.selectorString componentsSeparatedByString:@":"];
    NSUInteger numberOfArguments = self.numberOfArguments;
    
    for (NSUInteger argIndex = 2; argIndex < numberOfArguments; argIndex++) {
        assert(argIndex < self.signature.numberOfArguments);
        
        const char *argType = [self.signature getArgumentTypeAtIndex:argIndex] ?: "?";
        NSString *readableArgType = [FLEXRuntimeUtility readableTypeForEncoding:@(argType)];
        NSString *prettyComponent = [NSString
            stringWithFormat:@"%@:(%@) ",
            selectorComponents[argIndex - 2],
            readableArgType
        ];

        [components addObject:prettyComponent];
    }
    
    return components;
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"<%@ selector=%@, signature=%@>",
            NSStringFromClass(self.class), self.selectorString, self.signatureString];
}

- (void)examine {
    _implementation    = method_getImplementation(_objc_method);
    _selector          = method_getName(_objc_method);
    _numberOfArguments = method_getNumberOfArguments(_objc_method);
    _name              = NSStringFromSelector(_selector);
    _returnType        = (FLEXTypeEncoding *)_signature.methodReturnType ?: "";
    _returnSize        = _signature.methodReturnLength;
}

#pragma mark Public

- (void)setImplementation:(IMP)implementation {
    NSParameterAssert(implementation);
    method_setImplementation(self.objc_method, implementation);
    [self examine];
}

- (NSString *)typeEncoding {
    if (!_typeEncoding) {
        _typeEncoding = [_signatureString
            stringByReplacingOccurrencesOfString:@"[0-9]"
            withString:@""
            options:NSRegularExpressionSearch
            range:NSMakeRange(0, _signatureString.length)
        ];
    }
    
    return _typeEncoding;
}

- (NSString *)imagePath {
    if (!_imagePath) {
        Dl_info exeInfo;
        if (dladdr(_implementation, &exeInfo)) {
            _imagePath = exeInfo.dli_fname ? @(exeInfo.dli_fname) : @"";
        }
    }
    
    return _imagePath;
}

#pragma mark Misc

- (void)swapImplementations:(FLEXMethod *)method {
    method_exchangeImplementations(self.objc_method, method.objc_method);
    [self examine];
    [method examine];
}

// Some code borrowed from MAObjcRuntime, by Mike Ash.
- (id)sendMessage:(id)target, ... {
    id ret = nil;
    va_list args;
    va_start(args, target);
    
    switch (self.returnType[0]) {
        case FLEXTypeEncodingUnknown: {
            [self getReturnValue:NULL forMessageSend:target arguments:args];
            break;
        }
        case FLEXTypeEncodingChar: {
            char val = 0;
            [self getReturnValue:&val forMessageSend:target arguments:args];
            ret = @(val);
            break;
        }
        case FLEXTypeEncodingInt: {
            int val = 0;
            [self getReturnValue:&val forMessageSend:target arguments:args];
            ret = @(val);
            break;
        }
        case FLEXTypeEncodingShort: {
            short val = 0;
            [self getReturnValue:&val forMessageSend:target arguments:args];
            ret = @(val);
            break;
        }
        case FLEXTypeEncodingLong: {
            long val = 0;
            [self getReturnValue:&val forMessageSend:target arguments:args];
            ret = @(val);
            break;
        }
        case FLEXTypeEncodingLongLong: {
            long long val = 0;
            [self getReturnValue:&val forMessageSend:target arguments:args];
            ret = @(val);
            break;
        }
        case FLEXTypeEncodingUnsignedChar: {
            unsigned char val = 0;
            [self getReturnValue:&val forMessageSend:target arguments:args];
            ret = @(val);
            break;
        }
        case FLEXTypeEncodingUnsignedInt: {
            unsigned int val = 0;
            [self getReturnValue:&val forMessageSend:target arguments:args];
            ret = @(val);
            break;
        }
        case FLEXTypeEncodingUnsignedShort: {
            unsigned short val = 0;
            [self getReturnValue:&val forMessageSend:target arguments:args];
            ret = @(val);
            break;
        }
        case FLEXTypeEncodingUnsignedLong: {
            unsigned long val = 0;
            [self getReturnValue:&val forMessageSend:target arguments:args];
            ret = @(val);
            break;
        }
        case FLEXTypeEncodingUnsignedLongLong: {
            unsigned long long val = 0;
            [self getReturnValue:&val forMessageSend:target arguments:args];
            ret = @(val);
            break;
        }
        case FLEXTypeEncodingFloat: {
            float val = 0;
            [self getReturnValue:&val forMessageSend:target arguments:args];
            ret = @(val);
            break;
        }
        case FLEXTypeEncodingDouble: {
            double val = 0;
            [self getReturnValue:&val forMessageSend:target arguments:args];
            ret = @(val);
            break;
        }
        case FLEXTypeEncodingLongDouble: {
            long double val = 0;
            [self getReturnValue:&val forMessageSend:target arguments:args];
            ret = [NSValue value:&val withObjCType:self.returnType];
            break;
        }
        case FLEXTypeEncodingCBool: {
            bool val = 0;
            [self getReturnValue:&val forMessageSend:target arguments:args];
            ret = @(val);
            break;
        }
        case FLEXTypeEncodingVoid: {
            [self getReturnValue:NULL forMessageSend:target arguments:args];
            return nil;
            break;
        }
        case FLEXTypeEncodingCString: {
            char *val = 0;
            [self getReturnValue:&val forMessageSend:target arguments:args];
            ret = @(val);
            break;
        }
        case FLEXTypeEncodingObjcObject: {
            id val = nil;
            [self getReturnValue:&val forMessageSend:target arguments:args];
            ret = val;
            break;
        }
        case FLEXTypeEncodingObjcClass: {
            Class val = Nil;
            [self getReturnValue:&val forMessageSend:target arguments:args];
            ret = val;
            break;
        }
        case FLEXTypeEncodingSelector: {
            SEL val = 0;
            [self getReturnValue:&val forMessageSend:target arguments:args];
            ret = NSStringFromSelector(val);
            break;
        }
        case FLEXTypeEncodingArrayBegin: {
            void *val = 0;
            [self getReturnValue:&val forMessageSend:target arguments:args];
            ret = [NSValue valueWithBytes:val objCType:self.signature.methodReturnType];
            break;
        }
        case FLEXTypeEncodingUnionBegin:
        case FLEXTypeEncodingStructBegin: {
            if (self.signature.methodReturnLength) {
                void * val = malloc(self.signature.methodReturnLength);
                [self getReturnValue:val forMessageSend:target arguments:args];
                ret = [NSValue valueWithBytes:val objCType:self.signature.methodReturnType];
            } else {
                [self getReturnValue:NULL forMessageSend:target arguments:args];
            }
            break;
        }
        case FLEXTypeEncodingBitField: {
            [self getReturnValue:NULL forMessageSend:target arguments:args];
            break;
        }
        case FLEXTypeEncodingPointer: {
            void * val = 0;
            [self getReturnValue:&val forMessageSend:target arguments:args];
            ret = [NSValue valueWithPointer:val];
            break;
        }

        default: {
            [NSException raise:NSInvalidArgumentException
                        format:@"Unsupported type encoding: %s", (char *)self.returnType];
        }
    }
    
    va_end(args);
    return ret;
}

// Code borrowed from MAObjcRuntime, by Mike Ash.
- (void)getReturnValue:(void *)retPtr forMessageSend:(id)target, ... {
    va_list args;
    va_start(args, target);
    [self getReturnValue:retPtr forMessageSend:target arguments:args];
    va_end(args);
}

// Code borrowed from MAObjcRuntime, by Mike Ash.
- (void)getReturnValue:(void *)retPtr forMessageSend:(id)target arguments:(va_list)args {
    if (!_signature) {
        return;
    }
    
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:_signature];
    NSUInteger argumentCount = _signature.numberOfArguments;
    
    invocation.target = target;
    
    for (NSUInteger i = 2; i < argumentCount; i++) {
        int cookie = va_arg(args, int);
        if (cookie != FLEXMagicNumber) {
            [NSException
                raise:NSInternalInconsistencyException
                format:@"%s: incorrect magic cookie %08x; make sure you didn't forget "
                "any arguments and that all arguments are wrapped in FLEXArg().", __func__, cookie
            ];
        }
        const char *typeString = va_arg(args, char *);
        void *argPointer       = va_arg(args, void *);
        
        NSUInteger inSize, sigSize;
        NSGetSizeAndAlignment(typeString, &inSize, NULL);
        NSGetSizeAndAlignment([_signature getArgumentTypeAtIndex:i], &sigSize, NULL);
        
        if (inSize != sigSize) {
            [NSException
                raise:NSInternalInconsistencyException
                format:@"%s:size mismatch between passed-in argument and "
                "required argument; in type:%s (%lu) requested:%s (%lu)",
                __func__, typeString, (long)inSize, [_signature getArgumentTypeAtIndex:i], (long)sigSize
            ];
        }
        
        [invocation setArgument:argPointer atIndex:i];
    }
    
    // Hack to make NSInvocation invoke the desired implementation
    IMP imp = [invocation methodForSelector:NSSelectorFromString(@"invokeUsingIMP:")];
    void (*invokeWithIMP)(id, SEL, IMP) = (void *)imp;
    invokeWithIMP(invocation, 0, _implementation);
    
    if (_signature.methodReturnLength && retPtr) {
        [invocation getReturnValue:retPtr];
    }
}

@end


@implementation FLEXMethod (Comparison)

- (NSComparisonResult)compare:(FLEXMethod *)method {
    return [self.selectorString compare:method.selectorString];
}

@end
