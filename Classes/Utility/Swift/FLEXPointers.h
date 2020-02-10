//
//  FLEXPointers.h
//  FLEX
//
//  Created by Tanner on 2/10/20.
//  Copyright © 2020 Flipboard. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef FLEXPointers_h
#define FLEXPointers_h

constexpr BOOL is64bit() {
    #if __LP64__
    return YES;
    #else
    return NO;
    #endif
}

constexpr ssize_t existentialHeaderSize() {
    #if __LP64__
    return 16;
    #else
    return 8;
    #endif
}

constexpr void * bridge(id object) {
    return (__bridge void *)object;
}

//struct RelativePointer<P, T> {
//    P offset;
//    
//    T get() {
//        
//    }
//}

//void * valuePointer(void *value, void *typeInfo) {
//    
//    let kind = Kind(type: Value.self)
//    
//    switch kind {
//    case .struct:
//        return try withUnsafePointer(to: &value) { try body(valuePtr.mutable.raw) }
//    case .class:
//        return try withClassValuePointer(of: &value, body)
//    case .existential:
//        return try withExistentialValuePointer(of: &value, body)
//    default:
//        throw RuntimeError.couldNotGetPointer(type: Value.self, value: value)
//    }
//}

//func existentialValuePointer<Value, Result>(of value: inout Value, _ body: (UMRPointer)) {
//    // value is boxed as Any
//    let container = valuePtr.withMemoryRebound(to: ExistentialContainer.self, capacity: 1) {valuePtr.pointee}
//    let info = try metadata(of: container.type)
//    if info.kind == .class || info.size > ExistentialContainerBuffer.size() {
//        let base = valuePtr.withMemoryRebound(to: UMRPointer.self, capacity: 1) {valuePtr.pointee}
//        if info.kind == .struct {
//            return try body(base.advanced(by: existentialHeaderSize))
//        } else {
//            return try body(base)
//        }
//    } else {
//        return try body(valuePtr.mutable.raw)
//    }
//}

#endif /* FLEXPointers_h */
