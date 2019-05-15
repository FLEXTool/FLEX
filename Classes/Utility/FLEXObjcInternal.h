//
//  FLEXObjcInternal.h
//  FLEX
//
//  Created by Tanner Bennett on 11/1/18.
//

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

/// @brief Assumes memory is valid and readable.
/// @discussion objc-internal.h, objc-private.h, and objc-config.h
/// https://blog.timac.org/2016/1124-testing-if-an-arbitrary-pointer-is-a-valid-objective-c-object/
/// https://llvm.org/svn/llvm-project/lldb/trunk/examples/summaries/cocoa/objc_runtime.py
/// https://blog.timac.org/2016/1124-testing-if-an-arbitrary-pointer-is-a-valid-objective-c-object/
BOOL FLEXPointerIsValidObjcObject(const void * ptr);

#ifdef __cplusplus
}
#endif
