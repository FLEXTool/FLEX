//
//  FLEXSwiftRuntimeUtility.m
//  FLEX
//
//  Created by Tanner on 10/28/17.
//  Copyright © 2017 Flipboard. All rights reserved.
//

#import "FLEXSwiftRuntimeUtility.h"
#import "FLEXRuntimeUtility.h"
#import "SwiftMetadata.h"
#import <objc/runtime.h>

@implementation FLEXSwiftRuntimeUtility

+ (BOOL)swiftRuntimeAvailable {
    return [self SwiftObjectClass] != nil;
}

+ (Class)SwiftObjectClass {
    static Class SwiftObject = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SwiftObject = NSClassFromString(@"SwiftObject");
    });

    return SwiftObject;
}

+ (BOOL)isSwiftObjectOrClass:(id)objectOrClass {
    // Automatic NO if Swift is not in use
    Class SwiftObject = [self SwiftObjectClass];
    if (!SwiftObject) {
        return NO;
    }

    // Make sure we have the Class
    Class cls = objectOrClass;
    if (!object_isClass(objectOrClass)) {
        cls = object_getClass(objectOrClass);
    }

    // Determine if inherits from SwiftObject
    while (cls != nil && cls != SwiftObject) {
        cls = class_getSuperclass(cls);
    }

    return cls == SwiftObject;
}

+ (id)performSelector:(SEL)selector onSwiftObject:(id)object withArguments:(NSArray *)arguments error:(NSError *__autoreleasing *)error {
    return nil;
}

@end
