//
//  FLEXMacArgumentInputView.m
//  FLEX (macOS)
//

#import "FLEXMacArgumentInputView.h"
#import "FLEXMacUtility.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXTypeEncodingParser.h"
#import "FLEXRuntimeSafety.h"
#import "FLEXObjcInternal.h"

typedef NS_ENUM(NSUInteger, FLEXMacInputKind) {
    FLEXMacInputKindUnsupported,
    FLEXMacInputKindObject,
    FLEXMacInputKindClass,
    FLEXMacInputKindBool,
    FLEXMacInputKindNumber,
    FLEXMacInputKindStruct,
    FLEXMacInputKindSelector,
    FLEXMacInputKindCString,
};

#pragma mark - Scalar helpers

static BOOL FLEXMacIsNumericType(char type) {
    switch (type) {
        case 'c': case 'C': case 's': case 'S': case 'i': case 'I':
        case 'l': case 'L': case 'q': case 'Q': case 'f': case 'd': case 'B':
            return YES;
        default:
            return NO;
    }
}

static NSNumber *FLEXMacReadScalar(const void *ptr, char type) {
    switch (type) {
        case 'c': return @(*(const char *)ptr);
        case 'C': return @(*(const unsigned char *)ptr);
        case 's': return @(*(const short *)ptr);
        case 'S': return @(*(const unsigned short *)ptr);
        case 'i': return @(*(const int *)ptr);
        case 'I': return @(*(const unsigned int *)ptr);
        case 'l': return @(*(const long *)ptr);
        case 'L': return @(*(const unsigned long *)ptr);
        case 'q': return @(*(const long long *)ptr);
        case 'Q': return @(*(const unsigned long long *)ptr);
        case 'f': return @(*(const float *)ptr);
        case 'd': return @(*(const double *)ptr);
        case 'B': return @(*(const bool *)ptr);
        default: return nil;
    }
}

static BOOL FLEXMacWriteScalar(void *ptr, char type, NSString *string) {
    NSScanner *scanner = [NSScanner scannerWithString:
        [string stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet]
    ];
    if (type == 'f' || type == 'd') {
        double d = 0;
        if (![scanner scanDouble:&d] || !scanner.isAtEnd) return NO;
        if (type == 'f') *(float *)ptr = (float)d;
        else *(double *)ptr = d;
        return YES;
    }

    if (type == 'B') {
        NSString *lower = string.lowercaseString;
        *(bool *)ptr = [lower isEqualToString:@"yes"] || [lower isEqualToString:@"true"] || lower.integerValue != 0;
        return YES;
    }

    BOOL isUnsigned = (type == 'C' || type == 'S' || type == 'I' || type == 'L' || type == 'Q');
    if (isUnsigned) {
        unsigned long long u = 0;
        BOOL hex = [string.lowercaseString hasPrefix:@"0x"];
        if (hex ? ![scanner scanHexLongLong:&u] : ![scanner scanUnsignedLongLong:&u]) return NO;
        if (!scanner.isAtEnd) return NO;
        switch (type) {
            case 'C': *(unsigned char *)ptr = (unsigned char)u; break;
            case 'S': *(unsigned short *)ptr = (unsigned short)u; break;
            case 'I': *(unsigned int *)ptr = (unsigned int)u; break;
            case 'L': *(unsigned long *)ptr = (unsigned long)u; break;
            case 'Q': *(unsigned long long *)ptr = u; break;
        }
        return YES;
    }

    long long s = 0;
    if (![scanner scanLongLong:&s] || !scanner.isAtEnd) return NO;
    switch (type) {
        case 'c': *(char *)ptr = (char)s; break;
        case 's': *(short *)ptr = (short)s; break;
        case 'i': *(int *)ptr = (int)s; break;
        case 'l': *(long *)ptr = (long)s; break;
        case 'q': *(long long *)ptr = s; break;
    }
    return YES;
}

/// Strips method type qualifiers like 'r' (const) from an encoding
static const char *FLEXMacStripQualifiers(const char *type) {
    while (type && *type && strchr("rnNoORV", *type)) {
        type++;
    }
    return type;
}

/// Ivar encodings may contain field names, e.g. {CGRect="origin"{CGPoint="x"d"y"d}...};
/// @return the encoding without them, which the runtime helpers can parse
static NSString *FLEXMacStripFieldNames(const char *type) {
    NSString *string = @(type ?: "");
    if (![string containsString:@"\""]) {
        return string;
    }
    NSRegularExpression *names = [NSRegularExpression regularExpressionWithPattern:@"\"[^\"]*\"" options:0 error:nil];
    return [names stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, string.length) withTemplate:@""];
}

/// The names of the scalar (non-struct) fields in an encoding with field names, if any
static NSArray<NSString *> *FLEXMacLeafFieldNames(const char *type) {
    NSString *string = @(type ?: "");
    NSRegularExpression *names = [NSRegularExpression regularExpressionWithPattern:@"\"([^\"]*)\"(?=[^{\"])" options:0 error:nil];
    NSMutableArray *result = [NSMutableArray new];
    for (NSTextCheckingResult *match in [names matchesInString:string options:0 range:NSMakeRange(0, string.length)]) {
        [result addObject:[string substringWithRange:[match rangeAtIndex:1]]];
    }
    return result;
}

#pragma mark - Struct flattening

@interface FLEXMacStructField : NSObject
@property (nonatomic) char type;
@property (nonatomic) NSUInteger offset;
@property (nonatomic, copy) NSString *label;
@end
@implementation FLEXMacStructField
@end

/// @return NO if the struct contains a field which is not numeric
static BOOL FLEXMacFlattenStruct(const char *encoding, NSUInteger baseOffset, NSMutableArray<FLEXMacStructField *> *fields) {
    __block BOOL supported = YES;
    __block NSUInteger count = 0;
    [FLEXRuntimeUtility enumerateTypesInStructEncoding:encoding usingBlock:^(
        NSString *structName, const char *fieldType, NSString *pretty, NSUInteger idx, NSUInteger offset) {
        count++;
        fieldType = FLEXMacStripQualifiers(fieldType);
        if (fieldType[0] == FLEXTypeEncodingStructBegin) {
            if (!FLEXMacFlattenStruct(fieldType, baseOffset + offset, fields)) {
                supported = NO;
            }
        } else if (strlen(fieldType) == 1 && FLEXMacIsNumericType(fieldType[0])) {
            FLEXMacStructField *field = [FLEXMacStructField new];
            field.type = fieldType[0];
            field.offset = baseOffset + offset;
            field.label = pretty;
            [fields addObject:field];
        } else {
            supported = NO;
        }
    }];
    return supported && count > 0;
}

static NSArray<NSString *> *FLEXMacKnownStructFieldNames(NSString *structName) {
    static NSDictionary<NSString *, NSArray<NSString *> *> *names = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        names = @{
            @"CGRect": @[@"x", @"y", @"width", @"height"],
            @"CGPoint": @[@"x", @"y"],
            @"CGSize": @[@"width", @"height"],
            @"CGVector": @[@"dx", @"dy"],
            @"_NSRange": @[@"location", @"length"],
            @"NSEdgeInsets": @[@"top", @"left", @"bottom", @"right"],
            @"NSDirectionalEdgeInsets": @[@"top", @"leading", @"bottom", @"trailing"],
            @"CGAffineTransform": @[@"a", @"b", @"c", @"d", @"tx", @"ty"],
            @"CATransform3D": @[@"m11", @"m12", @"m13", @"m14", @"m21", @"m22", @"m23", @"m24",
                                @"m31", @"m32", @"m33", @"m34", @"m41", @"m42", @"m43", @"m44"],
        };
    });
    return names[structName];
}

static NSString *FLEXMacStructName(const char *encoding) {
    const char *equals = strchr(encoding, '=');
    if (encoding[0] != '{' || !equals) {
        return nil;
    }
    return [[NSString alloc] initWithBytes:encoding + 1 length:equals - encoding - 1 encoding:NSUTF8StringEncoding];
}

#pragma mark - Input view

@interface FLEXMacArgumentInputView ()
@property (nonatomic) FLEXMacInputKind kind;
@property (nonatomic, readwrite) NSString *typeEncoding;
@property (nonatomic) NSTextField *textField;
@property (nonatomic) NSButton *checkbox;
@property (nonatomic) NSArray<FLEXMacStructField *> *structFields;
@property (nonatomic) NSArray<NSTextField *> *structTextFields;
@property (nonatomic) NSUInteger structSize;
@end

@implementation FLEXMacArgumentInputView

+ (FLEXMacInputKind)kindForTypeEncoding:(const char *)typeEncoding {
    NSString *stripped = FLEXMacStripFieldNames(typeEncoding);
    const char *type = FLEXMacStripQualifiers(stripped.UTF8String);
    if (!type || !type[0]) {
        return FLEXMacInputKindUnsupported;
    }

    switch (type[0]) {
        case FLEXTypeEncodingObjcObject:
            // Blocks can't be entered
            return strcmp(type, "@?") == 0 ? FLEXMacInputKindUnsupported : FLEXMacInputKindObject;
        case FLEXTypeEncodingObjcClass:
            return FLEXMacInputKindClass;
        case FLEXTypeEncodingSelector:
            return FLEXMacInputKindSelector;
        case FLEXTypeEncodingCString:
            return FLEXMacInputKindCString;
        case 'B':
            return FLEXMacInputKindBool;
        case FLEXTypeEncodingStructBegin: {
            NSMutableArray *fields = [NSMutableArray new];
            return FLEXMacFlattenStruct(type, 0, fields) ? FLEXMacInputKindStruct : FLEXMacInputKindUnsupported;
        }
        default:
            if (strlen(type) == 1 && FLEXMacIsNumericType(type[0])) {
                return FLEXMacInputKindNumber;
            }
            return FLEXMacInputKindUnsupported;
    }
}

+ (BOOL)supportsTypeEncoding:(const char *)typeEncoding {
    return typeEncoding && [self kindForTypeEncoding:typeEncoding] != FLEXMacInputKindUnsupported;
}

+ (NSString *)descriptionForStructValue:(id)value {
    if (![value isKindOfClass:[NSValue class]] || [value isKindOfClass:[NSNumber class]]) {
        return nil;
    }
    const char *namedType = [(NSValue *)value objCType];
    NSString *stripped = FLEXMacStripFieldNames(namedType);
    const char *type = FLEXMacStripQualifiers(stripped.UTF8String);
    if (!type || type[0] != FLEXTypeEncodingStructBegin) {
        return nil;
    }

    NSMutableArray<FLEXMacStructField *> *fields = [NSMutableArray new];
    NSUInteger size = 0;
    if (!FLEXMacFlattenStruct(type, 0, fields) || !FLEXGetSizeAndAlignment(type, &size, NULL) || !size) {
        return nil;
    }

    NSArray<NSString *> *names = FLEXMacKnownStructFieldNames(FLEXMacStructName(type));
    if (names.count != fields.count) {
        names = FLEXMacLeafFieldNames(namedType);
    }
    if (names.count != fields.count) {
        names = nil;
    }

    void *buffer = calloc(1, size);
    [(NSValue *)value getValue:buffer size:size];
    NSMutableArray *parts = [NSMutableArray new];
    [fields enumerateObjectsUsingBlock:^(FLEXMacStructField *field, NSUInteger idx, BOOL *stop) {
        NSString *number = FLEXMacReadScalar((char *)buffer + field.offset, field.type).stringValue ?: @"?";
        [parts addObject:names ? [NSString stringWithFormat:@"%@: %@", names[idx], number] : number];
    }];
    free(buffer);

    NSString *name = FLEXMacStructName(type);
    return [NSString stringWithFormat:@"%@{%@}", name.length && ![name isEqualToString:@"?"] ? [name stringByAppendingString:@" "] : @"",
        [parts componentsJoinedByString:@", "]];
}

- (instancetype)initWithTypeEncoding:(const char *)typeEncoding title:(NSString *)title {
    self = [super initWithFrame:NSZeroRect];
    if (self) {
        _typeEncoding = @(typeEncoding ?: "");
        _kind = [FLEXMacArgumentInputView kindForTypeEncoding:typeEncoding];
        self.orientation = NSUserInterfaceLayoutOrientationVertical;
        self.alignment = NSLayoutAttributeLeading;
        self.spacing = 4;
        self.translatesAutoresizingMaskIntoConstraints = NO;

        NSString *readableType = [FLEXRuntimeUtility readableTypeForEncoding:self.typeEncoding] ?: self.typeEncoding;
        NSString *header = title.length ? [NSString stringWithFormat:@"%@  (%@)", title, readableType] : readableType;
        NSTextField *titleLabel = [NSTextField labelWithString:header];
        titleLabel.font = [NSFont boldSystemFontOfSize:12];
        titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self addArrangedSubview:titleLabel];

        [self buildInputs];
    }
    return self;
}

- (NSTextField *)makeTextField:(NSString *)placeholder {
    NSTextField *field = [NSTextField textFieldWithString:@""];
    field.placeholderString = placeholder;
    field.font = [FLEXMacUtility monospacedFontOfSize:12];
    field.translatesAutoresizingMaskIntoConstraints = NO;
    return field;
}

- (void)addFullWidth:(NSView *)view {
    [self addArrangedSubview:view];
    [view.leadingAnchor constraintEqualToAnchor:self.leadingAnchor].active = YES;
    [view.trailingAnchor constraintEqualToAnchor:self.trailingAnchor].active = YES;
}

- (void)addHint:(NSString *)hint {
    NSTextField *label = [NSTextField wrappingLabelWithString:hint];
    label.font = [NSFont systemFontOfSize:11];
    label.textColor = NSColor.secondaryLabelColor;
    label.selectable = NO;
    [self addFullWidth:label];
}

- (void)buildInputs {
    switch (self.kind) {
        case FLEXMacInputKindObject:
            self.textField = [self makeTextField:@"nil"];
            [self addFullWidth:self.textField];
            [self addHint:@"JSON (\"string\", 12, true, [..], {..}), plain text for strings, an address like 0x6000... for an existing object, or nil."];
            break;
        case FLEXMacInputKindClass:
            self.textField = [self makeTextField:@"Class name"];
            [self addFullWidth:self.textField];
            break;
        case FLEXMacInputKindSelector:
            self.textField = [self makeTextField:@"selectorName:"];
            [self addFullWidth:self.textField];
            break;
        case FLEXMacInputKindCString:
            self.textField = [self makeTextField:@"C string"];
            [self addFullWidth:self.textField];
            break;
        case FLEXMacInputKindNumber:
            self.textField = [self makeTextField:@"0"];
            [self addFullWidth:self.textField];
            break;
        case FLEXMacInputKindBool:
            self.checkbox = [NSButton checkboxWithTitle:@"YES" target:nil action:nil];
            [self addArrangedSubview:self.checkbox];
            break;
        case FLEXMacInputKindStruct:
            [self buildStructInputs];
            break;
        case FLEXMacInputKindUnsupported: {
            NSTextField *label = [NSTextField labelWithString:@"Editing this type is not supported."];
            label.textColor = NSColor.secondaryLabelColor;
            [self addArrangedSubview:label];
            break;
        }
    }
}

- (void)buildStructInputs {
    NSString *stripped = FLEXMacStripFieldNames(self.typeEncoding.UTF8String);
    const char *type = FLEXMacStripQualifiers(stripped.UTF8String);
    NSMutableArray<FLEXMacStructField *> *fields = [NSMutableArray new];
    FLEXMacFlattenStruct(type, 0, fields);
    NSUInteger size = 0;
    FLEXGetSizeAndAlignment(type, &size, NULL);
    self.structSize = size;
    self.structFields = fields;

    NSArray<NSString *> *names = FLEXMacKnownStructFieldNames(FLEXMacStructName(type));
    if (names.count != fields.count) {
        names = FLEXMacLeafFieldNames(self.typeEncoding.UTF8String);
    }
    if (names.count != fields.count) {
        names = nil;
    }

    NSGridView *grid = [NSGridView gridViewWithNumberOfColumns:2 rows:0];
    grid.rowSpacing = 4;
    grid.rowAlignment = NSGridRowAlignmentFirstBaseline;
    grid.columnSpacing = 8;
    grid.translatesAutoresizingMaskIntoConstraints = NO;

    NSMutableArray *textFields = [NSMutableArray new];
    [fields enumerateObjectsUsingBlock:^(FLEXMacStructField *field, NSUInteger idx, BOOL *stop) {
        NSString *label = names ? names[idx] : [NSString stringWithFormat:@"[%lu] %@", (unsigned long)idx, field.label];
        NSTextField *labelField = [NSTextField labelWithString:label];
        labelField.alignment = NSTextAlignmentRight;
        NSTextField *input = [self makeTextField:@"0"];
        [input.widthAnchor constraintGreaterThanOrEqualToConstant:160].active = YES;
        [grid addRowWithViews:@[labelField, input]];
        [textFields addObject:input];
    }];
    self.structTextFields = textFields;
    [self addFullWidth:grid];
}

- (NSView *)firstInputView {
    return self.textField ?: self.checkbox ?: self.structTextFields.firstObject ?: self;
}

#pragma mark Populating

- (void)populateWithValue:(id)value {
    switch (self.kind) {
        case FLEXMacInputKindObject: {
            NSString *string = nil;
            if (!value) {
                string = @"";
            } else if ([value isKindOfClass:[NSString class]]) {
                // Show strings as JSON so that "nil" and numbers are unambiguous
                string = [FLEXRuntimeUtility editableJSONStringForObject:value];
            } else {
                string = [FLEXRuntimeUtility editableJSONStringForObject:value];
                if (!string) {
                    string = [NSString stringWithFormat:@"%p", (__bridge void *)value];
                }
            }
            self.textField.stringValue = string ?: @"";
            break;
        }
        case FLEXMacInputKindClass:
            self.textField.stringValue = value ? NSStringFromClass(value) : @"";
            break;
        case FLEXMacInputKindSelector:
            if ([value isKindOfClass:[NSValue class]]) {
                SEL sel = NULL;
                [(NSValue *)value getValue:&sel];
                self.textField.stringValue = sel ? NSStringFromSelector(sel) : @"";
            } else if ([value isKindOfClass:[NSString class]]) {
                self.textField.stringValue = value;
            }
            break;
        case FLEXMacInputKindCString:
            if ([value isKindOfClass:[NSString class]]) {
                self.textField.stringValue = value;
            }
            break;
        case FLEXMacInputKindNumber:
            if ([value isKindOfClass:[NSNumber class]]) {
                self.textField.stringValue = [(NSNumber *)value stringValue];
            }
            break;
        case FLEXMacInputKindBool:
            if ([value isKindOfClass:[NSNumber class]]) {
                self.checkbox.state = [value boolValue] ? NSControlStateValueOn : NSControlStateValueOff;
            }
            break;
        case FLEXMacInputKindStruct:
            if ([value isKindOfClass:[NSValue class]] && self.structSize) {
                NSUInteger valueSize = 0;
                NSString *valueType = FLEXMacStripFieldNames([value objCType]);
                FLEXGetSizeAndAlignment(valueType.UTF8String, &valueSize, NULL);
                if (valueSize != self.structSize) {
                    break;
                }
                void *buffer = calloc(1, self.structSize);
                [(NSValue *)value getValue:buffer];
                [self.structFields enumerateObjectsUsingBlock:^(FLEXMacStructField *field, NSUInteger idx, BOOL *stop) {
                    NSNumber *number = FLEXMacReadScalar((char *)buffer + field.offset, field.type);
                    self.structTextFields[idx].stringValue = number.stringValue ?: @"0";
                }];
                free(buffer);
            }
            break;
        case FLEXMacInputKindUnsupported:
            break;
    }
}

#pragma mark Reading

- (NSError *)errorWithMessage:(NSString *)message {
    return [NSError errorWithDomain:@"FLEX" code:1 userInfo:@{ NSLocalizedDescriptionKey: message }];
}

- (Class)expectedObjectClass {
    NSString *type = @(FLEXMacStripQualifiers(self.typeEncoding.UTF8String));
    if (type.length > 3 && [type hasPrefix:@"@\""]) {
        NSString *name = [type substringWithRange:NSMakeRange(2, type.length - 3)];
        // Strip protocol qualifiers like <NSCopying>
        NSRange angle = [name rangeOfString:@"<"];
        if (angle.location != NSNotFound) {
            name = [name substringToIndex:angle.location];
        }
        return name.length ? NSClassFromString(name) : nil;
    }
    return nil;
}

- (id)inputValueWithError:(NSError **)error {
    NSString *text = [self.textField.stringValue
        stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet
    ] ?: @"";
    const char *type = self.typeEncoding.UTF8String;

    switch (self.kind) {
        case FLEXMacInputKindObject: {
            if (!text.length || [text isEqualToString:@"nil"]) {
                return nil;
            }

            // Addresses of existing objects
            if ([text.lowercaseString hasPrefix:@"0x"]) {
                unsigned long long address = 0;
                NSScanner *scanner = [NSScanner scannerWithString:text];
                if ([scanner scanHexLongLong:&address] && scanner.isAtEnd) {
                    if (FLEXPointerIsValidObjcObject((const void *)(uintptr_t)address)) {
                        return (__bridge id)(void *)(uintptr_t)address;
                    }
                    if (error) *error = [self errorWithMessage:[NSString stringWithFormat:@"%@ is not a valid object address", text]];
                    return nil;
                }
            }

            Class expected = self.expectedObjectClass;
            if (expected && [expected isSubclassOfClass:[NSURL class]]) {
                NSURL *url = [NSURL URLWithString:text];
                if (url) return url;
            }

            id json = [FLEXRuntimeUtility objectValueFromEditableJSONString:text];
            if (json) {
                return json;
            }
            // Fall back to treating the text as a plain string
            return text;
        }
        case FLEXMacInputKindClass: {
            if (!text.length || [text isEqualToString:@"nil"]) {
                return nil;
            }
            Class cls = NSClassFromString(text);
            if (!cls && error) {
                *error = [self errorWithMessage:[NSString stringWithFormat:@"No class named '%@'", text]];
            }
            return cls;
        }
        case FLEXMacInputKindSelector: {
            SEL sel = text.length ? NSSelectorFromString(text) : NULL;
            return [NSValue value:&sel withObjCType:type];
        }
        case FLEXMacInputKindCString: {
            // Intentionally leaked; the callee may hold on to the pointer
            const char *string = text.length ? strdup(text.UTF8String) : NULL;
            return [NSValue value:&string withObjCType:type];
        }
        case FLEXMacInputKindNumber: {
            const char *stripped = FLEXMacStripQualifiers(type);
            uint8_t buffer[16] = {0};
            if (!FLEXMacWriteScalar(buffer, stripped[0], text)) {
                if (error) *error = [self errorWithMessage:[NSString stringWithFormat:@"'%@' is not a valid number", text]];
                return nil;
            }
            return [NSValue value:buffer withObjCType:type];
        }
        case FLEXMacInputKindBool: {
            bool flag = self.checkbox.state == NSControlStateValueOn;
            return [NSValue value:&flag withObjCType:type];
        }
        case FLEXMacInputKindStruct: {
            void *buffer = calloc(1, MAX(self.structSize, 1));
            __block NSString *failure = nil;
            [self.structFields enumerateObjectsUsingBlock:^(FLEXMacStructField *field, NSUInteger idx, BOOL *stop) {
                NSString *fieldText = self.structTextFields[idx].stringValue;
                if (!fieldText.length) fieldText = @"0";
                if (!FLEXMacWriteScalar((char *)buffer + field.offset, field.type, fieldText)) {
                    failure = fieldText;
                    *stop = YES;
                }
            }];
            id value = nil;
            if (failure) {
                if (error) *error = [self errorWithMessage:[NSString stringWithFormat:@"'%@' is not a valid number", failure]];
            } else {
                value = [NSValue value:buffer withObjCType:type];
            }
            free(buffer);
            return value;
        }
        case FLEXMacInputKindUnsupported:
            if (error) *error = [self errorWithMessage:@"This type is not supported"];
            return nil;
    }
}

@end
