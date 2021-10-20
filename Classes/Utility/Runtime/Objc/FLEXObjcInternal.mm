//
//  FLEXObjcInternal.mm
//  FLEX
//
//  Created by Tanner Bennett on 11/1/18.
//

/*
 * Copyright (c) 2005-2007 Apple Inc.  All Rights Reserved.
 *
 * @APPLE_LICENSE_HEADER_START@
 *
 * This file contains Original Code and/or Modifications of Original Code
 * as defined in and that are subject to the Apple Public Source License
 * Version 2.0 (the 'License'). You may not use this file except in
 * compliance with the License. Please obtain a copy of the License at
 * http://www.opensource.apple.com/apsl/ and read it before using this
 * file.
 *
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
 * Please see the License for the specific language governing rights and
 * limitations under the License.
 *
 * @APPLE_LICENSE_HEADER_END@
 */

#import "FLEXObjcInternal.h"
#import <objc/runtime.h>
// For malloc_size
#import <malloc/malloc.h>
// For vm_region_64
#include <mach/mach.h>

#if __arm64e__
#include <ptrauth.h>
#endif

#define ALWAYS_INLINE inline __attribute__((always_inline))
#define NEVER_INLINE inline __attribute__((noinline))

// The macros below are copied straight from
// objc-internal.h, objc-private.h, objc-object.h, and objc-config.h with
// as few modifications as possible. Changes are noted in boxed comments.
// https://opensource.apple.com/source/objc4/objc4-723/
// https://opensource.apple.com/source/objc4/objc4-723/runtime/objc-internal.h.auto.html
// https://opensource.apple.com/source/objc4/objc4-723/runtime/objc-object.h.auto.html

/////////////////////
// objc-internal.h //
/////////////////////

#if OBJC_HAVE_TAGGED_POINTERS

///////////////////
// objc-object.h //
///////////////////

////////////////////////////////////////////////
// originally objc_object::isExtTaggedPointer //
////////////////////////////////////////////////
NS_INLINE BOOL flex_isExtTaggedPointer(const void *ptr)  {
    return ((uintptr_t)ptr & _OBJC_TAG_EXT_MASK) == _OBJC_TAG_EXT_MASK;
}

#endif // OBJC_HAVE_TAGGED_POINTERS

/////////////////////////////////////
// FLEXObjectInternal              //
// No Apple code beyond this point //
/////////////////////////////////////

extern "C" {

BOOL FLEXPointerIsReadable(const void *inPtr) {
    kern_return_t error = KERN_SUCCESS;

    vm_size_t vmsize;
#if __arm64e__
    // On arm64e, we need to strip the PAC from the pointer so the adress is readable
    vm_address_t address = (vm_address_t)ptrauth_strip(inPtr, ptrauth_key_function_pointer);
#else
    vm_address_t address = (vm_address_t)inPtr;
#endif
    vm_region_basic_info_data_t info;
    mach_msg_type_number_t info_count = VM_REGION_BASIC_INFO_COUNT_64;
    memory_object_name_t object;

    error = vm_region_64(
        mach_task_self(),
        &address,
        &vmsize,
        VM_REGION_BASIC_INFO,
        (vm_region_info_t)&info,
        &info_count,
        &object
    );

    if (error != KERN_SUCCESS) {
        // vm_region/vm_region_64 returned an error
        return NO;
    } else if (!(BOOL)(info.protection & VM_PROT_READ)) {
        return NO;
    }

#if __arm64e__
    address = (vm_address_t)ptrauth_strip(inPtr, ptrauth_key_function_pointer);
#else
    address = (vm_address_t)inPtr;
#endif
    
    // Read the memory
    vm_size_t size = 0;
    char buf[sizeof(uintptr_t)];
    error = vm_read_overwrite(mach_task_self(), address, sizeof(uintptr_t), (vm_address_t)buf, &size);
    if (error != KERN_SUCCESS) {
        // vm_read_overwrite returned an error
        return NO;
    }

    return YES;
}

/// Accepts addresses that may or may not be readable.
/// https://blog.timac.org/2016/1124-testing-if-an-arbitrary-pointer-is-a-valid-objective-c-object/
BOOL FLEXPointerIsValidObjcObject(const void *ptr) {
    uintptr_t pointer = (uintptr_t)ptr;

    if (!ptr) {
        return NO;
    }

#if OBJC_HAVE_TAGGED_POINTERS
    // Tagged pointers have 0x1 set, no other valid pointers do
    // objc-internal.h -> _objc_isTaggedPointer()
    if (flex_isTaggedPointer(ptr) || flex_isExtTaggedPointer(ptr)) {
        return YES;
    }
#endif

    // Check pointer alignment
    if ((pointer % sizeof(uintptr_t)) != 0) {
        return NO;
    }

    // From LLDB:
    // Pointers in a class_t will only have bits 0 through 46 set,
    // so if any pointer has bits 47 through 63 high, we know that this is not a valid isa
    // https://llvm.org/svn/llvm-project/lldb/trunk/examples/summaries/cocoa/objc_runtime.py
    if ((pointer & 0xFFFF800000000000) != 0) {
        return NO;
    }

    // Make sure dereferencing this address won't crash
    if (!FLEXPointerIsReadable(ptr)) {
        return NO;
    }

    // http://www.sealiesoftware.com/blog/archive/2013/09/24/objc_explain_Non-pointer_isa.html
    // We check if the returned class is readable because object_getClass
    // can return a garbage value when given a non-nil pointer to a non-object
    Class cls = object_getClass((__bridge id)ptr);
    if (!cls || !FLEXPointerIsReadable((__bridge void *)cls)) {
        return NO;
    }
    
    // Just because this pointer is readable doesn't mean whatever is at
    // it's ISA offset is readable. We need to do the same checks on it's ISA.
    // Even this isn't perfect, because once we call object_isClass, we're
    // going to dereference a member of the metaclass, which may or may not
    // be readable itself. For the time being there is no way to access it
    // to check here, and I have yet to hard-code a solution.
    Class metaclass = object_getClass(cls);
    if (!metaclass || !FLEXPointerIsReadable((__bridge void *)metaclass)) {
        return NO;
    }
    
    // Does the class pointer we got appear as a class to the runtime?
    if (!object_isClass(cls)) {
        return NO;
    }
    
    // Is the allocation size at least as large as the expected instance size?
    ssize_t instanceSize = class_getInstanceSize(cls);
    if (malloc_size(ptr) < instanceSize) {
        return NO;
    }

    return YES;
}


} // End extern "C"
