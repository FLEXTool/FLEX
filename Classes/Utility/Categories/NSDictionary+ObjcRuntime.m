//
//  NSDictionary+ObjcRuntime.m
//  FLEX
//
//  Derived from MirrorKit.
//  Created by Tanner on 7/5/15.
//  Copyright (c) 2015 Tanner Bennett. All rights reserved.
//

#import "NSDictionary+ObjcRuntime.h"
#import "FLEXRuntimeUtility.h"
#import "NSMutableAttributedString+FLEX.h"
#import "NSString+SyntaxHighlighting.h"

@implementation NSDictionary (ObjcRuntime)

/// See this link on how to construct a proper attributes string:
/// https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html
- (NSAttributedString *)propertyAttributesString {
    if (!self[kFLEXPropertyAttributeKeyTypeEncoding]) return nil;
    
    NSMutableAttributedString *attributes = [NSMutableAttributedString new];
    [attributes appendAttributedString:[NSAttributedString stringWithFormat:@"T%@,", self[kFLEXPropertyAttributeKeyTypeEncoding]]];
    
    for (NSString *attribute in self.allKeys) {
        FLEXPropertyAttribute c = (FLEXPropertyAttribute)[attribute characterAtIndex:0];
        switch (c) {
            case FLEXPropertyAttributeTypeEncoding:
                break;
            case FLEXPropertyAttributeBackingIvarName:
                [attributes appendAttributedString:[NSAttributedString stringWithFormat:@"%@%@",
                                                    kFLEXPropertyAttributeKeyBackingIvarName,
                                                    self[kFLEXPropertyAttributeKeyBackingIvarName]
                                                    ]];
                [attributes appendAttributedString:@",".attributedString];
                break;
            case FLEXPropertyAttributeCopy:
                if ([self[kFLEXPropertyAttributeKeyCopy] boolValue])
                    [attributes appendAttributedString:[NSAttributedString stringWithFormat:@"%@", kFLEXPropertyAttributeKeyCopy]];
                [attributes appendAttributedString:@",".attributedString];
                break;
            case FLEXPropertyAttributeCustomGetter:
                [attributes appendAttributedString:[NSAttributedString stringWithFormat:@"%@%@",
                                                    kFLEXPropertyAttributeKeyCustomGetter,
                                                    self[kFLEXPropertyAttributeKeyCustomGetter]
                                                    ]];
                [attributes appendAttributedString:@",".attributedString];
                break;
            case FLEXPropertyAttributeCustomSetter:
                [attributes appendAttributedString:[NSAttributedString stringWithFormat:@"%@%@",
                                                    kFLEXPropertyAttributeKeyCustomSetter,
                                                    self[kFLEXPropertyAttributeKeyCustomSetter]
                                                    ]];
                [attributes appendAttributedString:@",".attributedString];
                break;
            case FLEXPropertyAttributeDynamic:
                if ([self[kFLEXPropertyAttributeKeyDynamic] boolValue])
                    [attributes appendAttributedString:[NSAttributedString stringWithFormat:@"%@", kFLEXPropertyAttributeKeyDynamic]];
                [attributes appendAttributedString:@",".attributedString];
                break;
            case FLEXPropertyAttributeGarbageCollectible:
                [attributes appendAttributedString:[NSAttributedString stringWithFormat:@"%@", kFLEXPropertyAttributeKeyGarbageCollectable]];
                [attributes appendAttributedString:@",".attributedString];
                break;
            case FLEXPropertyAttributeNonAtomic:
                if ([self[kFLEXPropertyAttributeKeyNonAtomic] boolValue])
                    [attributes appendAttributedString:[NSAttributedString stringWithFormat:@"%@", kFLEXPropertyAttributeKeyNonAtomic]];
                [attributes appendAttributedString:@",".attributedString];
                break;
            case FLEXPropertyAttributeOldTypeEncoding:
                [attributes appendAttributedString:[NSAttributedString stringWithFormat:@"%@%@",
                                                    kFLEXPropertyAttributeKeyOldStyleTypeEncoding,
                                                    self[kFLEXPropertyAttributeKeyOldStyleTypeEncoding]
                                                    ]];
                [attributes appendAttributedString:@",".attributedString];
                break;
            case FLEXPropertyAttributeReadOnly:
                if ([self[kFLEXPropertyAttributeKeyReadOnly] boolValue])
                    [attributes appendAttributedString:[NSAttributedString stringWithFormat:@"%@", kFLEXPropertyAttributeKeyReadOnly]];
                [attributes appendAttributedString:@",".attributedString];
                break;
            case FLEXPropertyAttributeRetain:
                if ([self[kFLEXPropertyAttributeKeyRetain] boolValue])
                    [attributes appendAttributedString:[NSAttributedString stringWithFormat:@"%@", kFLEXPropertyAttributeKeyRetain]];
                [attributes appendAttributedString:@",".attributedString];
                break;
            case FLEXPropertyAttributeWeak:
                if ([self[kFLEXPropertyAttributeKeyWeak] boolValue])
                    [attributes appendAttributedString:[NSAttributedString stringWithFormat:@"%@", kFLEXPropertyAttributeKeyWeak]];
                [attributes appendAttributedString:@",".attributedString];
                break;
            default:
                return nil;
                break;
        }
    }
    
    [attributes deleteCharactersInRange:NSMakeRange(attributes.length - 1, 1)];
    return attributes.copy;
}

+ (instancetype)attributesDictionaryForProperty:(objc_property_t)property {
    NSMutableDictionary *attrs = [NSMutableDictionary new];

    for (NSString *key in FLEXRuntimeUtility.allPropertyAttributeKeys) {
        char *value = property_copyAttributeValue(property, key.UTF8String);
        if (value) {
            attrs[key] = [[NSString alloc]
                          initWithBytesNoCopy:value
                          length:strlen(value)
                          encoding:NSUTF8StringEncoding
                          freeWhenDone:YES
                          ];
        }
    }

    return attrs.copy;
}

@end
