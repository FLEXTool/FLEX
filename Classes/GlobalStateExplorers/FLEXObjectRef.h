//
//  FLEXObjectRef.h
//  FLEX
//
//  Created by Tanner Bennett on 7/24/18.
//  Copyright (c) 2018 Flipboard. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FLEXObjectRef : NSObject

+ (instancetype)referencing:(id)object;
+ (instancetype)referencing:(id)object ivar:(NSString *)ivarName;

+ (NSArray<FLEXObjectRef *> *)referencingAll:(NSArray *)objects;

/// For example, "NSString 0x1d4085d0" or "NSLayoutConstraint _object"
@property (nonatomic, readonly) NSString *reference;
@property (nonatomic, readonly) id object;

@end
