//
//  FLEXTypeEncodingParser.h
//  FLEX
//
//  Created by Tanner Bennett on 8/22/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// @return \c YES if the type is supported, \c NO otherwise
BOOL FLEXGetSizeAndAlignment(const char *type, NSUInteger * _Nullable sizep, NSUInteger * _Nullable alignp);

@interface FLEXTypeEncodingParser : NSObject

/// \c cleanedEncoding is necessary because a type encoding may contain a pointer
/// to an unsupported type. \c NSMethodSignature will pass each type to \c NSGetSizeAndAlignment
/// which will throw an exception on unsupported struct pointers, and this exception is caught
/// by \c NSMethodSignature, but it still bothers anyone debugging with \c objc_exception_throw
///
/// @param cleanedEncoding the "safe" type encoding you can pass to \c NSMethodSignature
/// @return whether the given type encoding can be passed to
/// \c NSMethodSignature without it throwing an exception.
+ (BOOL)methodTypeEncodingSupported:(NSString *)typeEncoding cleaned:(NSString *_Nonnull*_Nullable)cleanedEncoding;

/// @return The type encoding of an individual argument in a method's type encoding string.
/// Pass 0 to get the type of the return value. 1 and 2 are `self` and `_cmd` respectively.
+ (NSString *)type:(NSString *)typeEncoding forMethodArgumentAtIndex:(NSUInteger)idx;

/// @return The size in bytes of the typeof an individual argument in a method's type encoding string.
/// Pass 0 to get the size of the return value. 1 and 2 are `self` and `_cmd` respectively.
+ (ssize_t)size:(NSString *)typeEncoding forMethodArgumentAtIndex:(NSUInteger)idx;

/// @param unaligned whether to compute the aligned or unaligned size.
/// @return The size in bytes, or \c -1 if the type encoding is unsupported.
/// Do not pass in the result of \c method_getTypeEncoding
+ (ssize_t)sizeForTypeEncoding:(NSString *)type alignment:(nullable ssize_t *)alignOut unaligned:(BOOL)unaligned;

/// Defaults to \C unaligned:NO
+ (ssize_t)sizeForTypeEncoding:(NSString *)type alignment:(nullable ssize_t *)alignOut;

@end

NS_ASSUME_NONNULL_END
