//
//  FLEXHeapEnumerator.m
//  Flipboard
//
//  Created by Ryan Olson on 5/28/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//

#import "FLEXHeapEnumerator.h"
#import <malloc/malloc.h>
#import <mach/mach.h>
#import <objc/runtime.h>

static CFMutableSetRef registeredClasses;

// Mimics the objective-c object stucture for checking if a range of memory is an object.
typedef struct {
    Class isa;
} flex_maybe_object_t;

@implementation FLEXHeapEnumerator

static void range_callback(task_t task, void *context, unsigned type, vm_range_t *ranges, unsigned rangeCount)
{
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

static kern_return_t reader(__unused task_t remote_task, vm_address_t remote_address, __unused vm_size_t size, void **local_memory)
{
    *local_memory = (void *)remote_address;
    return KERN_SUCCESS;
}

+ (void)enumerateLiveObjectsUsingBlock:(flex_object_enumeration_block_t)block
{
    if (!block) {
        return;
    }
    
    // Refresh the class list on every call in case classes are added to the runtime.
    [self updateRegisteredClasses];
    
    // Inspired by:
    // http://llvm.org/svn/llvm-project/lldb/tags/RELEASE_34/final/examples/darwin/heap_find/heap/heap_find.cpp
    // https://gist.github.com/samdmarshall/17f4e66b5e2e579fd396
    
    vm_address_t *zones = NULL;
    unsigned int zoneCount = 0;
    kern_return_t result = malloc_get_all_zones(TASK_NULL, reader, &zones, &zoneCount);
    
    if (result == KERN_SUCCESS) {
        for (unsigned int i = 0; i < zoneCount; i++) {
            malloc_zone_t *zone = (malloc_zone_t *)zones[i];
            malloc_introspection_t *introspection = zone->introspect;

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

            // The largest realistic memory address varies by platform.
            // Only 48 bits are used by 64 bit machines while
            // 32 bit machines use all bits.
#if __arm64__
            static uintptr_t MAX_REALISTIC_ADDRESS = 0xFFFFFFFFFFFF;
#else
            static uintptr_t MAX_REALISTIC_ADDRESS = INT_MAX;
#endif

            // There is little documentation on when and why
            // any of these function pointers might be NULL
            // or garbage, so we resort to checking for NULL
            // and impossible memory addresses at least
            if (lock_zone && unlock_zone &&
                introspection->enumerator &&
                (uintptr_t)lock_zone < MAX_REALISTIC_ADDRESS &&
                (uintptr_t)unlock_zone < MAX_REALISTIC_ADDRESS) {
                lock_zone(zone);
                introspection->enumerator(TASK_NULL, (void *)&callback, MALLOC_PTR_IN_USE_RANGE_TYPE, (vm_address_t)zone, reader, &range_callback);
                unlock_zone(zone);
            }
        }
    }
}

+ (void)updateRegisteredClasses
{
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

@end
