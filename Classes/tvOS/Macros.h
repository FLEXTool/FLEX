//
// Based on http://stackoverflow.com/a/202511
//

#pragma mark - Enum Factory Macros
// expansion macro for enum value definition
#define ENUM_VALUE(name,assign) name assign,

// expansion macro for enum to string conversion
#define ENUM_CASE(name,assign) case name: return @#name;

// expansion macro for string to enum conversion
#define ENUM_STRCMP(name,assign) if ([string isEqualToString:@#name]) return name;

/// declare the access function and define enum values
#define DECLARE_ENUM(EnumType,ENUM_DEF) \
typedef enum EnumType { \
ENUM_DEF(ENUM_VALUE) \
}EnumType; \
NSString *_Nonnull NSStringFrom##EnumType(EnumType value); \
EnumType EnumType##FromNSString(NSString *_Nonnull string); \

// Define Functions
#define DEFINE_ENUM(EnumType, ENUM_DEF) \
NSString *_Nonnull NSStringFrom##EnumType(EnumType value) \
{ \
switch(value) \
{ \
ENUM_DEF(ENUM_CASE) \
default: return @""; \
} \
} \
EnumType EnumType##FromNSString(NSString *string) \
{ \
ENUM_DEF(ENUM_STRCMP) \
return (EnumType)0; \
} 
