//
//  NSDictionary+ObjcRuntime.h
//  FLEX
//
//  Derived from MirrorKit.
//  Created by Tanner on 7/5/15.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface NSDictionary (ObjcRuntime)

/// \c kFLEXPropertyAttributeKeyTypeEncoding is the only required key.
/// Keys representing a boolean value should have a value of \c YES instead of an empty string.
- (NSString *)propertyAttributesString;

+ (instancetype)attributesDictionaryForProperty:(objc_property_t)property;

@end
