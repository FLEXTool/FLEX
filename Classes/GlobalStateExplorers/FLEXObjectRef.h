//
//  FLEXObjectRef.h
//  FLEX
//
//  Created by Tanner Bennett on 7/24/18.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FLEXObjectRef : NSObject

+ (instancetype)referencing:(id)object;
+ (instancetype)referencing:(id)object ivar:(NSString *)ivarName;

+ (NSArray<FLEXObjectRef *> *)referencingAll:(NSArray *)objects;
/// Classes do not have a summary, and the reference is just the class name.
+ (NSArray<FLEXObjectRef *> *)referencingClasses:(NSArray<Class> *)classes;

/// For example, "NSString 0x1d4085d0" or "NSLayoutConstraint _object"
@property (nonatomic, readonly) NSString *reference;
/// For instances, this is the result of -[FLEXRuntimeUtility summaryForObject:]
/// For classes, there is no summary.
@property (nonatomic, readonly) NSString *summary;
@property (nonatomic, readonly) id object;

@end
