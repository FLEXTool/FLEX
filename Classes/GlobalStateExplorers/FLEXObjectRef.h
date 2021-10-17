//
//  FLEXObjectRef.h
//  FLEX
//
//  Created by Tanner Bennett on 7/24/18.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FLEXObjectRef : NSObject

/// Reference an object without affecting its lifespan or or emitting reference-counting operations.
+ (instancetype)unretained:(__unsafe_unretained id)object;
+ (instancetype)unretained:(__unsafe_unretained id)object ivar:(NSString *)ivarName;

/// Reference an object and control its lifespan.
+ (instancetype)retained:(id)object;
+ (instancetype)retained:(id)object ivar:(NSString *)ivarName;

/// Reference an object and conditionally choose to retain it or not.
+ (instancetype)referencing:(__unsafe_unretained id)object retained:(BOOL)retain;
+ (instancetype)referencing:(__unsafe_unretained id)object ivar:(NSString *)ivarName retained:(BOOL)retain;

+ (NSArray<FLEXObjectRef *> *)referencingAll:(NSArray *)objects retained:(BOOL)retain;
/// Classes do not have a summary, and the reference is just the class name.
+ (NSArray<FLEXObjectRef *> *)referencingClasses:(NSArray<Class> *)classes;

/// For example, "NSString 0x1d4085d0" or "NSLayoutConstraint _object"
@property (nonatomic, readonly) NSString *reference;
/// For instances, this is the result of -[FLEXRuntimeUtility summaryForObject:]
/// For classes, there is no summary.
@property (nonatomic, readonly) NSString *summary;
@property (nonatomic, readonly, unsafe_unretained) id object;

/// Retains the referenced object if it is not already retained
- (void)retainObject;
/// Releases the referenced object if it is already retained
- (void)releaseObject;

@end
