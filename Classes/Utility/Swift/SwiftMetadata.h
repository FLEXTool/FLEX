//
//  SwiftMetadata.h
//  Swift Test
//
//  Created by Tanner on 10/28/17.
//  Copyright © 2017 Tanner Bennett. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef int32_t ContextDescriptorFlags;

typedef NS_ENUM(NSUInteger, NominalTypeDescriptorKind) {
    NominalTypeDescriptorKindClass = 0,
    NominalTypeDescriptorKindStruct = 1,
    NominalTypeDescriptorKindEnum = 2
};

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

typedef union _CommonMetadata {
    MetadataKind kind;
    Class isa;
} Metadata;

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
    RelativeOffset mangledName; // char[]
    RelativeOffset fieldTypesAccessor; // int64_t
    RelativeOffset fieldDescriptor; // FieldDescriptor
    RelativeOffset superClass; // id
    int32_t negativeSizeAndBoundsUnion;
    int32_t metadataPositiveSizeInWords;
    int32_t numImmediateMembers;
    int32_t numberOfFields;
    RelativeOffset offsetToTheFieldOffsetVector; // int64_t[]
//    TargetTypeGenericContextDescriptorHeader genericContextHeader;
} ClassTypeDescriptor;

typedef struct _NominalTypeDescriptor {
    NominalTypeDescriptorKind kind;
    const char *mangledName;
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
} NominalTypeDescriptor;

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




