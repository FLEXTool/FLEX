//
//  FLEXHeapEnumerator.h
//  Flipboard
//
//  Created by Ryan Olson on 5/28/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import <Foundation/Foundation.h>
@class FLEXObjectRef;

typedef void (^flex_object_enumeration_block_t)(__unsafe_unretained id object, __unsafe_unretained Class actualClass);

@interface FLEXHeapEnumerator : NSObject

+ (void)enumerateLiveObjectsUsingBlock:(flex_object_enumeration_block_t)block;

/// Returned references are not validated beyond containing a valid isa.
/// To validate them yourself, pass each reference's object to \c FLEXPointerIsValidObjcObject
+ (NSArray<FLEXObjectRef *> *)instancesOfClassWithName:(NSString *)className retained:(BOOL)retain;
+ (NSArray<FLEXObjectRef *> *)subclassesOfClassWithName:(NSString *)className;
/// Returned references have been validated via \c FLEXPointerIsValidObjcObject
+ (NSArray<FLEXObjectRef *> *)objectsWithReferencesToObject:(id)object retained:(BOOL)retain;

@end
