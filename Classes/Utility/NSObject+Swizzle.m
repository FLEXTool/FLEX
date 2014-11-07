//
//  NSArray+Class.m
//

#import <objc/runtime.h>

#import "NSObject+Swizzle.h"

@implementation NSObject (Swizzle)

+ (void)swizzleInstanceMethod:(SEL)firstMethod withMethod:(SEL)secondMethod
{
    @synchronized (self)
    {
        Class class = [self class];
        
        [[self class] swizzleInstanceMethod:firstMethod withMethod:secondMethod inClass:class];
    }
}

+ (void)swizzleInstanceMethod:(SEL)firstMethod withMethod:(SEL)secondMethod inClass:(Class)class
{
    SEL originalSelector = firstMethod;
    SEL swizzledSelector = secondMethod;
    
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    BOOL didAddMethod = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod)
    {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    }
    else
    {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

+ (void)swizzleClassMethod:(SEL)firstMethod withMethod:(SEL)secondMethod
{
    @synchronized (self)
    {
        Class class = object_getClass((id)self);
        
        [self swizzleClassMethod:firstMethod withMethod:secondMethod inClass:class];
    }
}

+ (void)swizzleClassMethod:(SEL)firstMethod withMethod:(SEL)secondMethod inClass:(Class)class
{
    SEL originalSelector = firstMethod;
    SEL swizzledSelector = secondMethod;
    
    Method originalMethod = class_getClassMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    BOOL didAddMethod = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod)
    {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    }
    else
    {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

@end
