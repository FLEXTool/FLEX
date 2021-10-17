//
//  FLEXHeapEnumerator.m
//  Flipboard
//
//  Created by Ryan Olson on 5/28/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXHeapEnumerator.h"
#import "FLEXObjcInternal.h"
#import "FLEXObjectRef.h"
#import "NSObject+FLEX_Reflection.h"
#import "NSString+FLEX.h"
#import <malloc/malloc.h>
#import <mach/mach.h>
#import <objc/runtime.h>

static CFMutableSetRef registeredClasses;

// Mimics the objective-c object structure for checking if a range of memory is an object.
typedef struct {
    Class isa;
} flex_maybe_object_t;

@implementation FLEXHeapEnumerator

static void range_callback(task_t task, void *context, unsigned type, vm_range_t *ranges, unsigned rangeCount) {
    if (!context) {
        return;
    }
    
    for (unsigned int i = 0; i < rangeCount; i++) {
        vm_range_t range = ranges[i];
        flex_maybe_object_t *tryObject = (flex_maybe_object_t *)range.address;
        Class tryClass = NULL;
#ifdef __arm64__
        // See http://www.sealiesoftware.com/blog/archive/2013/09/24/objc_explain_Non-pointer_isa.html
        extern uint64_t objc_debug_isa_class_mask WEAK_IMPORT_ATTRIBUTE;
        tryClass = (__bridge Class)((void *)((uint64_t)tryObject->isa & objc_debug_isa_class_mask));
#else
        tryClass = tryObject->isa;
#endif
        // If the class pointer matches one in our set of class pointers from the runtime, then we should have an object.
        if (CFSetContainsValue(registeredClasses, (__bridge const void *)(tryClass))) {
            (*(flex_object_enumeration_block_t __unsafe_unretained *)context)((__bridge id)tryObject, tryClass);
        }
    }
}

static kern_return_t reader(__unused task_t remote_task, vm_address_t remote_address, __unused vm_size_t size, void **local_memory) {
    *local_memory = (void *)remote_address;
    return KERN_SUCCESS;
}

+ (void)enumerateLiveObjectsUsingBlock:(flex_object_enumeration_block_t)block {
    if (!block) {
        return;
    }
    
    // Refresh the class list on every call in case classes are added to the runtime.
    [self updateRegisteredClasses];
    
    // Inspired by:
    // https://llvm.org/svn/llvm-project/lldb/tags/RELEASE_34/final/examples/darwin/heap_find/heap/heap_find.cpp
    // https://gist.github.com/samdmarshall/17f4e66b5e2e579fd396
    
    vm_address_t *zones = NULL;
    unsigned int zoneCount = 0;
    kern_return_t result = malloc_get_all_zones(TASK_NULL, reader, &zones, &zoneCount);
    
    if (result == KERN_SUCCESS) {
        for (unsigned int i = 0; i < zoneCount; i++) {
            malloc_zone_t *zone = (malloc_zone_t *)zones[i];
            malloc_introspection_t *introspection = zone->introspect;

            // This may explain why some zone functions are
            // sometimes invalid; perhaps not all zones support them?
            if (!introspection) {
                continue;
            }

            void (*lock_zone)(malloc_zone_t *zone)   = introspection->force_lock;
            void (*unlock_zone)(malloc_zone_t *zone) = introspection->force_unlock;

            // Callback has to unlock the zone so we freely allocate memory inside the given block
            flex_object_enumeration_block_t callback = ^(__unsafe_unretained id object, __unsafe_unretained Class actualClass) {
                unlock_zone(zone);
                block(object, actualClass);
                lock_zone(zone);
            };
            
            BOOL lockZoneValid = FLEXPointerIsReadable(lock_zone);
            BOOL unlockZoneValid =  FLEXPointerIsReadable(unlock_zone);

            // There is little documentation on when and why
            // any of these function pointers might be NULL
            // or garbage, so we resort to checking for NULL
            // and whether the pointer is readable
            if (introspection->enumerator && lockZoneValid && unlockZoneValid) {
                lock_zone(zone);
                introspection->enumerator(TASK_NULL, (void *)&callback, MALLOC_PTR_IN_USE_RANGE_TYPE, (vm_address_t)zone, reader, &range_callback);
                unlock_zone(zone);
            }
        }
    }
}

+ (void)updateRegisteredClasses {
    if (!registeredClasses) {
        registeredClasses = CFSetCreateMutable(NULL, 0, NULL);
    } else {
        CFSetRemoveAllValues(registeredClasses);
    }
    unsigned int count = 0;
    Class *classes = objc_copyClassList(&count);
    for (unsigned int i = 0; i < count; i++) {
        CFSetAddValue(registeredClasses, (__bridge const void *)(classes[i]));
    }
    free(classes);
}

+ (NSArray<FLEXObjectRef *> *)instancesOfClassWithName:(NSString *)className retained:(BOOL)retain {
    const char *classNameCString = className.UTF8String;
    NSMutableArray *instances = [NSMutableArray new];
    [FLEXHeapEnumerator enumerateLiveObjectsUsingBlock:^(__unsafe_unretained id object, __unsafe_unretained Class actualClass) {
        if (strcmp(classNameCString, class_getName(actualClass)) == 0) {
            // Note: objects of certain classes crash when retain is called.
            // It is up to the user to avoid tapping into instance lists for these classes.
            // Ex. OS_dispatch_queue_specific_queue
            // In the future, we could provide some kind of warning for classes that are known to be problematic.
            if (malloc_size((__bridge const void *)(object)) > 0) {
                [instances addObject:object];
            }
        }
    }];

    NSArray<FLEXObjectRef *> *references = [FLEXObjectRef referencingAll:instances retained:retain];
    return references;
}

+ (NSArray<FLEXObjectRef *> *)subclassesOfClassWithName:(NSString *)className {
    NSArray<Class> *classes = FLEXGetAllSubclasses(NSClassFromString(className), NO);
    NSArray<FLEXObjectRef *> *references = [FLEXObjectRef referencingClasses:classes];
    return references;
}

+ (NSArray<FLEXObjectRef *> *)objectsWithReferencesToObject:(id)object retained:(BOOL)retain {
    static Class SwiftObjectClass = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SwiftObjectClass = NSClassFromString(@"SwiftObject");
        if (!SwiftObjectClass) {
            SwiftObjectClass = NSClassFromString(@"Swift._SwiftObject");
        }
    });

    NSMutableArray<FLEXObjectRef *> *instances = [NSMutableArray new];
    [FLEXHeapEnumerator enumerateLiveObjectsUsingBlock:^(__unsafe_unretained id tryObject, __unsafe_unretained Class actualClass) {
        // Skip known-invalid objects
        if (!FLEXPointerIsValidObjcObject((__bridge void *)tryObject)) {
            return;
        }
        
        // Get all the ivars on the object. Start with the class and and travel up the
        // inheritance chain. Once we find a match, record it and move on to the next object.
        // There's no reason to find multiple matches within the same object.
        Class tryClass = actualClass;
        while (tryClass) {
            unsigned int ivarCount = 0;
            Ivar *ivars = class_copyIvarList(tryClass, &ivarCount);

            for (unsigned int ivarIndex = 0; ivarIndex < ivarCount; ivarIndex++) {
                Ivar ivar = ivars[ivarIndex];
                NSString *typeEncoding = @(ivar_getTypeEncoding(ivar) ?: "");

                if (typeEncoding.flex_typeIsObjectOrClass) {
                    ptrdiff_t offset = ivar_getOffset(ivar);
                    uintptr_t *fieldPointer = (__bridge void *)tryObject + offset;

                    if (*fieldPointer == (uintptr_t)(__bridge void *)object) {
                        NSString *ivarName = @(ivar_getName(ivar) ?: "???");
                        id ref = [FLEXObjectRef referencing:tryObject ivar:ivarName retained:retain];
                        [instances addObject:ref];
                        return;
                    }
                }
            }

            free(ivars);
            tryClass = class_getSuperclass(tryClass);
        }
    }];

    return instances;
}

@end
