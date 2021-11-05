//
//  FLEXRuntimeSafety.h
//  FLEX
//
//  Created by Tanner on 3/25/17.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#pragma mark - Classes

extern NSUInteger const kFLEXKnownUnsafeClassCount;
extern const Class * FLEXKnownUnsafeClassList(void);
extern NSSet * FLEXKnownUnsafeClassNames(void);
extern CFSetRef FLEXKnownUnsafeClasses;

static Class cNSObject = nil, cNSProxy = nil;

__attribute__((constructor))
static void FLEXInitKnownRootClasses(void) {
    cNSObject = [NSObject class];
    cNSProxy = [NSProxy class];
}

static inline BOOL FLEXClassIsSafe(Class cls) {
    // Is it nil or known to be unsafe?
    if (!cls || CFSetContainsValue(FLEXKnownUnsafeClasses, (__bridge void *)cls)) {
        return NO;
    }
    
    // Is it a known root class?
    if (!class_getSuperclass(cls)) {
        return cls == cNSObject || cls == cNSProxy;
    }
    
    // Probably safe
    return YES;
}

static inline BOOL FLEXClassNameIsSafe(NSString *cls) {
    if (!cls) return NO;
    
    NSSet *ignored = FLEXKnownUnsafeClassNames();
    return ![ignored containsObject:cls];
}

#pragma mark - Ivars

extern CFSetRef FLEXKnownUnsafeIvars;

static inline BOOL FLEXIvarIsSafe(Ivar ivar) {
    if (!ivar) return NO;

    return !CFSetContainsValue(FLEXKnownUnsafeIvars, ivar);
}
