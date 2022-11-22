//
//  FLEXHeapEnumerator.h
//  Flipboard
//
//  Created by Ryan Olson on 5/28/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import <Foundation/Foundation.h>
@class FLEXObjectRef;

NS_ASSUME_NONNULL_BEGIN

typedef void (^flex_object_enumeration_block_t)(__unsafe_unretained id object, __unsafe_unretained Class actualClass);

@interface FLEXHeapEnumerator : NSObject

/// Use carefully; this method puts a global lock on the heap in between callbacks.
/// 
/// Inspired by:
/// [heap_find.cpp](https://llvm.org/svn/llvm-project/lldb/tags/RELEASE_34/final/examples/darwin/heap_find/heap/heap_find.cpp)
/// and [samdmarshall](https://gist.github.com/samdmarshall/17f4e66b5e2e579fd396)
+ (void)enumerateLiveObjectsUsingBlock:(flex_object_enumeration_block_t)callback
NS_SWIFT_UNAVAILABLE("Use one of the other methods instead.");

/// Returned references are not validated beyond containing a valid isa.
/// To validate them yourself, pass each reference's object to \c FLEXPointerIsValidObjcObject
+ (NSArray<FLEXObjectRef *> *)instancesOfClassWithName:(NSString *)className retained:(BOOL)retain;
+ (NSArray<FLEXObjectRef *> *)subclassesOfClassWithName:(NSString *)className;

/// Returned references have been validated via \c FLEXPointerIsValidObjcObject
/// @param object the object to find references to
/// @param retain whether to retain the objects referencing \c object
+ (NSArray<FLEXObjectRef *> *)objectsWithReferencesToObject:(id)object retained:(BOOL)retain;

@end

NS_ASSUME_NONNULL_END
