//
//  NSObject+Reflection.m
//  FLEX
//
//  Derived from MirrorKit.
//  Created by Tanner on 6/30/15.
//  Copyright (c) 2015 Tanner Bennett. All rights reserved.
//

#import "NSObject+Reflection.h"
#import "FLEXClassBuilder.h"
#import "FLEXMirror.h"
#import "FLEXProperty.h"
#import "FLEXMethod.h"
#import "FLEXIvar.h"
#import "FLEXPropertyAttributes.h"
#import "NSArray+Functional.h"


NSString * FLEXTypeEncodingString(const char *returnType, NSUInteger count, ...) {
    if (returnType == NULL) return nil;
    
    NSMutableString *encoding = [NSMutableString string];
    [encoding appendFormat:@"%s%s%s", returnType, @encode(id), @encode(SEL)];
    
    va_list args;
    va_start(args, count);
    char *type = va_arg(args, char *);
    for (NSUInteger i = 0; i < count; i++, type = va_arg(args, char *)) {
        [encoding appendFormat:@"%s", type];
    }
    va_end(args);
    
    return encoding.copy;
}


#pragma mark NSProxy

@interface NSProxy (AnyObjectAdditions) @end
@implementation NSProxy (AnyObjectAdditions)

+ (void)load {
    // We need to get all of the methods in this file and add them to NSProxy. 
    // To do this we we need the class itself and it's metaclass.
    Class NSProxyClass = [NSProxy class];
    Class NSProxy_meta = object_getClass(NSProxyClass);
    
    // Copy all of the "flex_" methods from NSObject
    id filterFunc = ^BOOL(FLEXMethod *method, NSUInteger idx) {
        return [method.name hasPrefix:@"flex_"];
    };
    NSArray *instanceMethods = [[NSObject flex_allInstanceMethods] flex_filtered:filterFunc];
    NSArray *classMethods = [[NSObject flex_allClassMethods] flex_filtered:filterFunc];
    
    FLEXClassBuilder *proxy = [FLEXClassBuilder builderForClass:NSProxyClass];
    FLEXClassBuilder *meta  = [FLEXClassBuilder builderForClass:NSProxy_meta];
    [proxy addMethods:instanceMethods];
    [meta addMethods:classMethods];
}

@end

#pragma mark Reflection

@implementation NSObject (Reflection)

+ (FLEXMirror *)flex_reflection {
    return [FLEXMirror reflect:self];
}

- (FLEXMirror *)flex_reflection {
    return [FLEXMirror reflect:self];
}

/// Code borrowed from MAObjCRuntime by Mike Ash
+ (NSArray *)flex_allSubclasses {
    Class *buffer = NULL;
    
    int count, size;
    do {
        count  = objc_getClassList(NULL, 0);
        buffer = (Class *)realloc(buffer, count * sizeof(*buffer));
        size   = objc_getClassList(buffer, count);
    } while (size != count);
    
    NSMutableArray *array = [NSMutableArray array];
    for (int i = 0; i < count; i++) {
        Class candidate = buffer[i];
        Class superclass = candidate;
        while (superclass) {
            if (superclass == self) {
                [array addObject:candidate];
                break;
            }
            superclass = class_getSuperclass(superclass);
        }
    }
    
    free(buffer);
    return array;
}

- (Class)flex_setClass:(Class)cls {
    return object_setClass(self, cls);
}

+ (Class)flex_metaclass {
    return objc_getMetaClass(NSStringFromClass(self.class).UTF8String);
}

+ (size_t)flex_instanceSize {
    return class_getInstanceSize(self.class);
}

+ (Class)flex_setSuperclass:(Class)superclass {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return class_setSuperclass(self, superclass);
    #pragma clang diagnostic pop
}

+ (NSArray<Class> *)flex_classHierarchy {
    NSMutableArray *classes = [NSMutableArray array];
    Class cls = self;
    do {
        [classes addObject:cls];
    } while ((cls = [cls superclass]));

    return classes.copy;
}

@end


#pragma mark Methods

@implementation NSObject (Methods)

+ (NSArray<FLEXMethod *> *)flex_allMethods {
    NSMutableArray *instanceMethods = (id)self.flex_allInstanceMethods;
    [instanceMethods addObjectsFromArray:self.flex_allClassMethods];
    return instanceMethods;
}

+ (NSArray<FLEXMethod *> *)flex_allInstanceMethods {
    unsigned int mcount;
    Method *objcmethods = class_copyMethodList([self class], &mcount);

    NSMutableArray *methods = [NSMutableArray array];
    for (int i = 0; i < mcount; i++) {
        FLEXMethod *m = [FLEXMethod method:objcmethods[i] isInstanceMethod:YES];
        if (m) {
            [methods addObject:m];
        }
    }

    free(objcmethods);
    return methods;
}

+ (NSArray<FLEXMethod *> *)flex_allClassMethods {
    unsigned int mcount;
    Method *objcmethods = class_copyMethodList(self.flex_metaclass, &mcount);

    NSMutableArray *methods = [NSMutableArray array];
    for (int i = 0; i < mcount; i++) {
        FLEXMethod *m = [FLEXMethod method:objcmethods[i] isInstanceMethod:NO];
        if (m) {
            [methods addObject:m];
        }
    }

    free(objcmethods);
    return methods;
}

+ (FLEXMethod *)flex_methodNamed:(NSString *)name {
    Method m = class_getInstanceMethod([self class], NSSelectorFromString(name));
    if (m == NULL) {
        return nil;
    }

    return [FLEXMethod method:m isInstanceMethod:YES];
}

+ (FLEXMethod *)flex_classMethodNamed:(NSString *)name {
    Method m = class_getClassMethod([self class], NSSelectorFromString(name));
    if (m == NULL) {
        return nil;
    }

    return [FLEXMethod method:m isInstanceMethod:NO];
}

+ (BOOL)addMethod:(SEL)selector
     typeEncoding:(NSString *)typeEncoding
   implementation:(IMP)implementaiton
      toInstances:(BOOL)instance {
    return class_addMethod(instance ? self.class : self.flex_metaclass, selector, implementaiton, typeEncoding.UTF8String);
}

+ (IMP)replaceImplementationOfMethod:(FLEXMethodBase *)method with:(IMP)implementation useInstance:(BOOL)instance {
    return class_replaceMethod(instance ? self.class : self.flex_metaclass, method.selector, implementation, method.typeEncoding.UTF8String);
}

+ (void)swizzle:(FLEXMethodBase *)original with:(FLEXMethodBase *)other onInstance:(BOOL)instance {
    [self swizzleBySelector:original.selector with:other.selector onInstance:instance];
}

+ (BOOL)swizzleByName:(NSString *)original with:(NSString *)other onInstance:(BOOL)instance {
    SEL originalMethod = NSSelectorFromString(original);
    SEL newMethod      = NSSelectorFromString(other);
    if (originalMethod == 0 || newMethod == 0) {
        return NO;
    }

    [self swizzleBySelector:originalMethod with:newMethod onInstance:instance];
    return YES;
}

+ (void)swizzleBySelector:(SEL)original with:(SEL)other onInstance:(BOOL)instance {
    Class cls = instance ? self.class : self.flex_metaclass;
    Method originalMethod = class_getInstanceMethod(cls, original);
    Method newMethod = class_getInstanceMethod(cls, other);
    if (class_addMethod(cls, original, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
        class_replaceMethod(cls, other, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, newMethod);
    }
}

@end


#pragma mark Ivars

@implementation NSObject (Ivars)

+ (NSArray<FLEXIvar *> *)flex_allIvars {
    unsigned int ivcount;
    Ivar *objcivars = class_copyIvarList([self class], &ivcount);
    
    NSMutableArray *ivars = [NSMutableArray array];
    for (int i = 0; i < ivcount; i++) {
        [ivars addObject:[FLEXIvar ivar:objcivars[i]]];
    }

    free(objcivars);
    return ivars;
}

+ (FLEXIvar *)flex_ivarNamed:(NSString *)name {
    Ivar i = class_getInstanceVariable([self class], name.UTF8String);
    if (i == NULL) {
        return nil;
    }

    return [FLEXIvar ivar:i];
}

#pragma mark Get address
- (void *)flex_getIvarAddress:(FLEXIvar *)ivar {
    return (uint8_t *)(__bridge void *)self + ivar.offset;
}

- (void *)flex_getObjcIvarAddress:(Ivar)ivar {
    return (uint8_t *)(__bridge void *)self + ivar_getOffset(ivar);
}

- (void *)flex_getIvarAddressByName:(NSString *)name {
    Ivar ivar = class_getInstanceVariable(self.class, name.UTF8String);
    if (!ivar) return 0;
    
    return (uint8_t *)(__bridge void *)self + ivar_getOffset(ivar);
}

#pragma mark Set ivar object
- (void)flex_setIvar:(FLEXIvar *)ivar object:(id)value {
    object_setIvar(self, ivar.objc_ivar, value);
}

- (BOOL)flex_setIvarByName:(NSString *)name object:(id)value {
    Ivar ivar = class_getInstanceVariable(self.class, name.UTF8String);
    if (!ivar) return NO;
    
    object_setIvar(self, ivar, value);
    return YES;
}

- (void)flex_setObjcIvar:(Ivar)ivar object:(id)value {
    object_setIvar(self, ivar, value);
}

#pragma mark Set ivar value
- (void)flex_setIvar:(FLEXIvar *)ivar value:(void *)value size:(size_t)size {
    void *address = [self flex_getIvarAddress:ivar];
    memcpy(address, value, size);
}

- (BOOL)flex_setIvarByName:(NSString *)name value:(void *)value size:(size_t)size {
    Ivar ivar = class_getInstanceVariable(self.class, name.UTF8String);
    if (!ivar) return NO;
    
    [self flex_setObjcIvar:ivar value:value size:size];
    return YES;
}

- (void)flex_setObjcIvar:(Ivar)ivar value:(void *)value size:(size_t)size {
    void *address = [self flex_getObjcIvarAddress:ivar];
    memcpy(address, value, size);
}

@end


#pragma mark Properties

@implementation NSObject (Properties)

+ (NSArray<FLEXProperty *> *)flex_allProperties {
    NSMutableArray *instanceProperties = (id)self.flex_allInstanceProperties;
    [instanceProperties addObjectsFromArray:self.flex_allClassProperties];
    return instanceProperties;
}

+ (NSArray<FLEXProperty *> *)flex_allInstanceProperties {
    unsigned int pcount;
    objc_property_t *objcproperties = class_copyPropertyList(self, &pcount);
    
    NSMutableArray *properties = [NSMutableArray array];
    for (int i = 0; i < pcount; i++) {
        [properties addObject:[FLEXProperty property:objcproperties[i] onClass:self]];
    }

    free(objcproperties);
    return properties;
}

+ (NSArray<FLEXProperty *> *)flex_allClassProperties {
    Class metaclass = self.flex_metaclass;
    unsigned int pcount;
    objc_property_t *objcproperties = class_copyPropertyList(metaclass, &pcount);

    NSMutableArray *properties = [NSMutableArray array];
    for (int i = 0; i < pcount; i++) {
        [properties addObject:[FLEXProperty property:objcproperties[i] onClass:metaclass]];
    }

    free(objcproperties);
    return properties;
}

+ (FLEXProperty *)flex_propertyNamed:(NSString *)name {
    objc_property_t p = class_getProperty([self class], name.UTF8String);
    if (p == NULL) {
        return nil;
    }

    return [FLEXProperty property:p onClass:self];
}

+ (FLEXProperty *)flex_classPropertyNamed:(NSString *)name {
    objc_property_t p = class_getProperty(object_getClass(self), name.UTF8String);
    if (p == NULL) {
        return nil;
    }

    return [FLEXProperty property:p onClass:object_getClass(self)];
}

+ (void)flex_replaceProperty:(FLEXProperty *)property {
    [self flex_replaceProperty:property.name attributes:property.attributes];
}

+ (void)flex_replaceProperty:(NSString *)name attributes:(FLEXPropertyAttributes *)attributes {
    unsigned int count;
    objc_property_attribute_t *objc_attributes = [attributes copyAttributesList:&count];
    class_replaceProperty([self class], name.UTF8String, objc_attributes, count);
    free(objc_attributes);
}

@end


