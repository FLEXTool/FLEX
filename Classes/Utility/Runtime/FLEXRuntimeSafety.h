//
//  FLEXRuntimeSafety.h
//  FLEX
//
//  Created by Tanner on 3/25/17.
//

#import <Foundation/Foundation.h>


extern NSUInteger const kFLEXKnownUnsafeClassCount;
extern const Class * FLEXKnownUnsafeClassList();
extern NSSet * FLEXKnownUnsafeClassNames();
extern CFSetRef FLEXKnownUnsafeClasses;

static inline BOOL FLEXClassIsSafe(Class cls) {
    if (!cls) return NO;

    return CFSetContainsValue(FLEXKnownUnsafeClasses, (__bridge void *)cls);
}

static inline BOOL FLEXClassNameIsSafe(NSString *cls) {
    if (!cls) return NO;
    
    NSSet *ignored = FLEXKnownUnsafeClassNames();
    return ![ignored containsObject:cls];
}
