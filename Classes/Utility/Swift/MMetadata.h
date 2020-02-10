//
//  Metadata.h
//  FLEX
//
//  Created by Tanner on 2/10/20.
//  Copyright © 2020 Flipboard. All rights reserved.
//

#ifndef Metadata_h
#define Metadata_h

#import "SwiftMetadata.h"
#import <objc/runtime.h>

/// See https://github.com/apple/swift/blob/master/docs/ABI/TypeMetadata.rst#class-metadata

class Kind {
public:
    enum Value : short {
        struct_,
        enum_,
        optional,
        opaque,
        tuple,
        function,
        existential,
        metatype,
        objCClassWrapper,
        existentialMetatype,
        foreignClass,
        heapLocalVariable,
        heapGenericLocalVariable,
        errorObject,
        class_,
    };
    
private:
    Value value;
    
public:
    
    enum : uintptr_t {
        NonHeap = 0x200,
        RuntimePrivate = 0x100,
        NonType = 0x400,
    };
    
    Kind() = default;
    constexpr Kind(Value kind) : value(kind) { }
    
    Kind(uintptr_t flag) {
        switch (flag) {
            case 0:
                value = class_; break;
            case 1:
                value = struct_; break;
            case (0 | NonHeap):
                value = struct_; break;
            case 2:
                value = enum_; break;
            case (1 | NonHeap):
                value = enum_; break;
            case 3:
                value = optional; break;
            case (2 | NonHeap):
                value = optional; break;
            case 8:
                value = opaque; break;
            case (3 | NonHeap):
                value = foreignClass; break;
            case 9:
                value = tuple; break;
            case (0 | RuntimePrivate | NonHeap):
                value = opaque; break;
            case 10:
                value = function; break;
            case (1 | RuntimePrivate | NonHeap):
                value = tuple; break;
            case 12:
                value = existential; break;
            case (2 | RuntimePrivate | NonHeap):
                value = function; break;
            case 13:
                value = metatype; break;
            case (3 | RuntimePrivate | NonHeap):
                value = existential; break;
            case 14:
                value = objCClassWrapper; break;
            case (4 | RuntimePrivate | NonHeap):
                value = metatype; break;
            case 15:
                value = existentialMetatype; break;
            case (5 | RuntimePrivate | NonHeap):
                value = objCClassWrapper; break;
            case 16:
                value = foreignClass; break;
            case (6 | RuntimePrivate | NonHeap):
                value = existentialMetatype; break;
            case 64:
                value = heapLocalVariable; break;
            case (0 | NonType):
                value = heapLocalVariable; break;
            case 65:
                value = heapGenericLocalVariable; break;
            case (0 | NonType | RuntimePrivate):
                value = heapGenericLocalVariable; break;
            case 128:
                value = errorObject; break;
            case (1 | NonType | RuntimePrivate):
                value = errorObject; break;
            default:
                if (flag > 4096) {
                    value = class_; break;
                } else {
                    @throw NSInvalidArgumentException;
                }
        }
    }
    
    operator Value() const { return value; }  // Allow switch and comparisons.
                                              // note: Putting constexpr here causes
                                              // clang to stop warning on incomplete
                                              // case handling.
    explicit operator bool() = delete;        // Prevent usage: if(fruit)
    
    constexpr bool myMethod() const { return value == class_; }
};

constexpr NSInteger * metadataPointer(void *type) {
    return (NSInteger *)type;
}

NSString * getObjectClassName(id object) {
    Class cls = object_getClass(object);
    ClassMetadata *metadata = (__bridge ClassMetadata *)cls;
    const char *name = metadata->nominalTypeDescriptor->mangledName.get();
    return @(name);
}

//func swiftObject() -> Any.Type {
//    class Temp {}
//    let md = ClassMetadata(type: Temp.self)
//    return md.pointer.pointee.superClass
//}

NSInteger classIsSwiftMask() {
    if (@available(macOS 10.14.4, iOS 12.2, tvOS 12.2, watchOS 5.2, *)) {
        return 2;
    }
    
    return 1;
}

#endif /* Metadata_h */
