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

static kern_return_t memory_reader(task_t task, vm_address_t remote_address, vm_size_t size, void **local_memory)
{
    *local_memory = (void *)remote_address;
    return KERN_SUCCESS;
}

static void range_callback(task_t task, void *context, unsigned type, vm_range_t *ranges, unsigned rangeCount)
{
    flex_object_enumeration_block_t block = (__bridge flex_object_enumeration_block_t)context;
    if (!block) {
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
            block((__bridge id)tryObject, tryClass);
        }
    }
}

+ (void)enumerateLiveObjectsUsingBlock:(flex_object_enumeration_block_t)block
{
    if (!block) {
        return;
    }
    
    // Refresh the class list on every call in case classes are added to the runtime.
    [self updateRegisteredClasses];
    
    // For another exmple of enumerating through malloc ranges (which helped my understanding of the api) see:
    // http://llvm.org/svn/llvm-project/lldb/tags/RELEASE_34/final/examples/darwin/heap_find/heap/heap_find.cpp
    // Also https://gist.github.com/samdmarshall/17f4e66b5e2e579fd396
    vm_address_t *zones = NULL;
    unsigned int zoneCount = 0;
    kern_return_t result = malloc_get_all_zones(mach_task_self(), &memory_reader, &zones, &zoneCount);
    if (result == KERN_SUCCESS) {
        for (unsigned int i = 0; i < zoneCount; i++) {
            malloc_zone_t *zone = (malloc_zone_t *)zones[i];
            if (zone->introspect && zone->introspect->enumerator) {
                zone->introspect->enumerator(mach_task_self(), (__bridge void *)(block), MALLOC_PTR_IN_USE_RANGE_TYPE, zones[i], &memory_reader, &range_callback);
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
