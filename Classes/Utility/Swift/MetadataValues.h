//
//  MetadataValues.h
//  FLEX
//
//  Created by Tanner on 2/10/20.
//  Taken from swift/ABI/MetadataValues.h
//

#ifndef MetadataValues_h
#define MetadataValues_h

/// Kinds of context descriptor.
enum class ContextDescriptorKind : uint8_t {
    /// This context descriptor represents a module.
    Module = 0,
    
    /// This context descriptor represents an extension.
    Extension = 1,
    
    /// This context descriptor represents an anonymous possibly-generic context
    /// such as a function body.
    Anonymous = 2,
    
    /// This context descriptor represents a protocol context.
    Protocol = 3,
    
    /// This context descriptor represents an opaque type alias.
    OpaqueType = 4,
    
    /// First kind that represents a type of any sort.
    Type_First = 16,
    
    /// This context descriptor represents a class.
    Class = Type_First,
    
    /// This context descriptor represents a struct.
    Struct = Type_First + 1,
    
    /// This context descriptor represents an enum.
    Enum = Type_First + 2,
    
    /// Last kind that represents a type of any sort.
    Type_Last = 31,
};

/// Common flags stored in the first 32-bit word of any context descriptor.
struct ContextDescriptorFlags {
private:
    uint32_t value;
    
    explicit constexpr ContextDescriptorFlags(uint32_t value) : value(value) {}
    
public:
    constexpr ContextDescriptorFlags() : value(0) {}
    constexpr ContextDescriptorFlags(ContextDescriptorKind kind,
                                     bool isGeneric,
                                     bool isUnique,
                                     uint8_t version,
                                     uint16_t kindSpecificFlags)
    : ContextDescriptorFlags(ContextDescriptorFlags()
        .withKind(kind)
        .withGeneric(isGeneric)
        .withUnique(isUnique)
        .withVersion(version)
        .withKindSpecificFlags(kindSpecificFlags))
    { }
    
    /// The kind of context this descriptor describes.
    constexpr ContextDescriptorKind getKind() const {
        return ContextDescriptorKind(value & 0x1Fu);
    }
    
    /// Whether the context being described is generic.
    constexpr bool isGeneric() const {
        return (value & 0x80u) != 0;
    }
    
    /// Whether this is a unique record describing the referenced context.
    constexpr bool isUnique() const {
        return (value & 0x40u) != 0;
    }
    
    /// The format version of the descriptor. Higher version numbers may have
    /// additional fields that aren't present in older versions.
    constexpr uint8_t getVersion() const {
        return (value >> 8u) & 0xFFu;
    }
    
    /// The most significant two bytes of the flags word, which can have
    /// kind-specific meaning.
    constexpr uint16_t getKindSpecificFlags() const {
        return (value >> 16u) & 0xFFFFu;
    }
    
    constexpr ContextDescriptorFlags withKind(ContextDescriptorKind kind) const {
        return assert((uint8_t(kind) & 0x1F) == uint8_t(kind)),
        ContextDescriptorFlags((value & 0xFFFFFFE0u) | uint8_t(kind));
    }
    
    constexpr ContextDescriptorFlags withGeneric(bool isGeneric) const {
        return ContextDescriptorFlags((value & 0xFFFFFF7Fu)
                                      | (isGeneric ? 0x80u : 0));
    }
    
    constexpr ContextDescriptorFlags withUnique(bool isUnique) const {
        return ContextDescriptorFlags((value & 0xFFFFFFBFu)
                                      | (isUnique ? 0x40u : 0));
    }
    
    constexpr ContextDescriptorFlags withVersion(uint8_t version) const {
        return ContextDescriptorFlags((value & 0xFFFF00FFu) | (version << 8u));
    }
    
    constexpr ContextDescriptorFlags
    withKindSpecificFlags(uint16_t flags) const {
        return ContextDescriptorFlags((value & 0xFFFFu) | (flags << 16u));
    }
    
    constexpr uint32_t getIntValue() const {
        return value;
    }
};

#endif /* MetadataValues_h */
