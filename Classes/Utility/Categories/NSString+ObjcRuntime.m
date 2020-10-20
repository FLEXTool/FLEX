//
//  NSString+ObjcRuntime.m
//  FLEX
//
//  Derived from MirrorKit.
//  Created by Tanner on 7/1/15.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "NSString+ObjcRuntime.h"
#import "FLEXRuntimeUtility.h"

@implementation NSString (Utilities)

- (NSString *)stringbyDeletingCharacterAtIndex:(NSUInteger)idx {
    NSMutableString *string = self.mutableCopy;
    [string replaceCharactersInRange:NSMakeRange(idx, 1) withString:@""];
    return string;
}

/// See this link on how to construct a proper attributes string:
/// https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html
- (NSDictionary *)propertyAttributes {
    if (!self.length) return nil;
    
    NSMutableDictionary *attributes = [NSMutableDictionary new];
    
    NSArray *components = [self componentsSeparatedByString:@","];
    for (NSString *attribute in components) {
        FLEXPropertyAttribute c = (FLEXPropertyAttribute)[attribute characterAtIndex:0];
        switch (c) {
            case FLEXPropertyAttributeTypeEncoding:
                // Note: the type encoding here is not always correct. Radar: FB7499230
                attributes[kFLEXPropertyAttributeKeyTypeEncoding] = [attribute stringbyDeletingCharacterAtIndex:0];
                break;
            case FLEXPropertyAttributeBackingIvarName:
                attributes[kFLEXPropertyAttributeKeyBackingIvarName] = [attribute stringbyDeletingCharacterAtIndex:0];
                break;
            case FLEXPropertyAttributeCopy:
                attributes[kFLEXPropertyAttributeKeyCopy] = @YES;
                break;
            case FLEXPropertyAttributeCustomGetter:
                attributes[kFLEXPropertyAttributeKeyCustomGetter] = [attribute stringbyDeletingCharacterAtIndex:0];
                break;
            case FLEXPropertyAttributeCustomSetter:
                attributes[kFLEXPropertyAttributeKeyCustomSetter] = [attribute stringbyDeletingCharacterAtIndex:0];
                break;
            case FLEXPropertyAttributeDynamic:
                attributes[kFLEXPropertyAttributeKeyDynamic] = @YES;
                break;
            case FLEXPropertyAttributeGarbageCollectible:
                attributes[kFLEXPropertyAttributeKeyGarbageCollectable] = @YES;
                break;
            case FLEXPropertyAttributeNonAtomic:
                attributes[kFLEXPropertyAttributeKeyNonAtomic] = @YES;
                break;
            case FLEXPropertyAttributeOldTypeEncoding:
                attributes[kFLEXPropertyAttributeKeyOldStyleTypeEncoding] = [attribute stringbyDeletingCharacterAtIndex:0];
                break;
            case FLEXPropertyAttributeReadOnly:
                attributes[kFLEXPropertyAttributeKeyReadOnly] = @YES;
                break;
            case FLEXPropertyAttributeRetain:
                attributes[kFLEXPropertyAttributeKeyRetain] = @YES;
                break;
            case FLEXPropertyAttributeWeak:
                attributes[kFLEXPropertyAttributeKeyWeak] = @YES;
                break;
        }
    }

    return attributes;
}

@end
