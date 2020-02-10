//
//  SwiftMetadata.h
//  Swift Test
//
//  Created by Tanner on 10/28/17.
//  Copyright © 2017 Tanner Bennett. All rights reserved.
//

#include "FLEXPointers.h"
#include "RelativePointer.h"
#include "MetadataValues.h"
#include <MacTypes.h>

using namespace swift;

#pragma mark - Integral Types

typedef NS_ENUM(NSUInteger, MetadataKind) {
    MetadataKindStruct = 1,
    MetadataKindEnum,
    MetadataKindOptional,
    MetadataKindOpaque = 8,
    MetadataKindTuple,
    MetadataKindFunction,
    MetadataKindExistential = 12,
    MetadataKindMetatype,
    MetadataKindObjcClassWrapper,
    MetadataKindExistentialMetatype,
    MetadataKindForeignClass,
    MetadataKindHeapLocalVariable = 64,
    MetadataKindHeapGenericLocalVariable = 65,
    MetadataKindErrorObject = 128
//  MetadataKindClass = isa
};

#pragma mark - IDK

typedef union _CommonMetadata {
    MetadataKind kind;
    Class isa;
} Metadata;

#pragma mark - Type Descriptors

struct ContextDescriptor {
    ContextDescriptorFlags flags;
    RelativeIndirectablePointer<ContextDescriptor, true> parent;
    
    bool isGeneric() const { return flags.isGeneric(); }
    bool isUnique() const { return flags.isUnique(); }
    ContextDescriptorKind getKind() const { return flags.getKind(); }
    
    /// Get the generic context information for this context, or null if the
    /// context is not generic.
    const TargetGenericContext<Runtime> *getGenericContext() const;
    
    unsigned genericParamCount() const {
      auto *genericContext = getGenericContext();
      return genericContext
                ? genericContext->getGenericContextHeader().NumParams
                : 0;
    }
}

/// For classes and structs
typedef struct _StructureDescriptor {
    NSInteger fieldCount;
    NSInteger fieldOffsetVectorOffset;
    const char **names;
    Metadata **(*fieldTypesAccessor)(void *typeMetadata);
} StructureDescriptor;

/// For enums
typedef struct _EnumDescriptor {
    NSUInteger payloadInfo;
    NSUInteger noPayloadCaseCount;
    const char **caseNames;
    Metadata **(*fieldTypesAccessor)(void *typeMetadata);
} EnumDescriptor;

typedef struct ClassTypeDescriptor {
    ContextDescriptorFlags flags;
    int32_t parent;
    RelativeDirectPointer<char> mangledName;
    RelativeDirectPointer<int64_t> fieldTypesAccessor;
    RelativeDirectPointer<void *> fieldDescriptor; // FieldDescriptor
    RelativeDirectPointer<Class> superClass; // id
    int32_t negativeSizeAndBoundsUnion;
    int32_t metadataPositiveSizeInWords;
    int32_t numImmediateMembers;
    int32_t numberOfFields;
    RelativeDirectPointer<int64_t> offsetToTheFieldOffsetVector; // int64_t[]
//    TargetTypeGenericContextDescriptorHeader genericContextHeader;
} ClassTypeDescriptor;

struct NominalTypeDescriptor {
    enum Kind : NSUInteger {
        Class  = 0,
        Struct = 1,
        Enum   = 2
    };
    
    NominalTypeDescriptor::Kind kind;
    RelativeDirectPointer<char> mangledName;
    union {
        StructureDescriptor ivars; // structs / classes
        EnumDescriptor cases; // enums
    } typeInfo;
    struct {
        void *metadataPattern;
        NSUInteger parameterVectorOffset;
        NSUInteger typeParamCount; // Includes associated types
        NSUInteger formalTypeParamCount;
        NSUInteger witnessTableCount[1]; // Variable-length with size .typeParamCount
    } generic;
};

struct ClassTypeDescriptor : NominalTypeDescriptor {
    RelativeDirectPointer<NSInteger> fieldTypes;
    
}

#define _High8BitMask 0xFF00000000000000
#define _High8Offset 24

#define LowBits(highbits) 8*sizeof(NSUInteger) - highbits

#define ArgumentIsInOut(arg) (arg & 0x1)
#define EnumPayloadGetCaseCount(enum) (enum->payloadInfo & 0xFFFFFF)
#define EnumPayloadGetSizeOffset(enum) ((enum->payloadInfo & _High8BitMask) >> _High8Offset)

typedef struct _SwiftClassMetadata {
    Class metaclass;
    struct _SwiftClassMetadata *superclass;
    uintptr_t reserved[2];
    uintptr_t rodata; // (rodata & 0x1) -> isSwiftClass, except SwiftObject
    UInt32 classFlags;
    UInt32 instanceAddressOffset;
    UInt32 instanceSize;
    UInt16 instanceAlignmentMask;
    UInt16 reserved_;
    UInt32 classObjectSize;
    UInt32 classObjectAddressPoint;
    NominalTypeDescriptor *nominalTypeDescriptor;

    // Inline variable-sized arrays
    struct ClassHierarchyInfo {
        struct _SwiftClassMetadata *parent; // Currently always nil
//      struct GenericParameterVector {
//          TypeMetadata *T, *U, *V;
//          GenericWitnessTable *T_wt, *U_wt, *V_wt;
//      } genericParameters[genericCount];
//      IMP vtable[methodCount];
//      idk FieldOffsetVector;
    } classHierarchy[1]; // Sized to superclass count
} ClassMetadata;

typedef struct _SwiftStructMetadata {
    MetadataKind kind;
    NominalTypeDescriptor *type;
    Metadata *parent; // Always nil for now
    NSUInteger fieldOffsets[1]; // Sized to ivar count
//  struct GenericParameterVector {
//      TypeMetadata *T, *U, *V;
//      GenericWitnessTable *T_wt, *U_wt, *V_wt;
//  } genericParameters[genericCount];
} StructMetadata;

typedef struct _SwiftEnumMetadata {
    MetadataKind kind;
    NominalTypeDescriptor *type;
    Metadata *parent; // Always nil for now
//  struct GenericParameterVector {
//      TypeMetadata *T, *U, *V;
//      GenericWitnessTable *T_wt, *U_wt, *V_wt;
//  } genericParameters[genericCount];
} EnumMetadata;

typedef struct _SwiftTupleMetadata {
    MetadataKind kind;
    NSUInteger numberOfArguments;
    const char *names; // Inline array of names like ["foo", "bar", etc]
    struct {
        NominalTypeDescriptor *type;
        NSUInteger offset;
    } arguments[1]; // Sized to .numberOfArguments
} TupleMetadata;

typedef struct _SwiftFunctionMetadata {
    MetadataKind kind;
    UInt8 throws;
    UInt8 metadataConvention;
    NSUInteger numberOfArguments : LowBits(16);
    Metadata *arguments[1]; // Sized to numberOfArguments
//  Metadata *returnType;
} FunctionMetadata;

typedef struct _SwiftProtocolMetadata {
    MetadataKind kind;
    union {
        struct {
            BOOL classConstrained : 1;
            NSUInteger witnessTableCount : 31;
        } flags;
        NSUInteger unused;
    } layout;
    NSUInteger conformedCount;
    void *protocolDescriptors;
} ProtocolMetadata;

typedef struct _SwiftMetatypeMetadata {
    MetadataKind kind;
    Metadata *instanceType;
} MetatypeMetadata;




