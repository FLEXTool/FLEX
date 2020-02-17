//
//  FLEXTypeEncodingParser.m
//  FLEX
//
//  Created by Tanner Bennett on 8/22/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import "FLEXTypeEncodingParser.h"
#import "FLEXRuntimeUtility.h"

#define S(__ch) ({ \
    unichar __c = __ch; \
    [[NSString alloc] initWithCharacters:&__c length:1]; \
})

BOOL FLEXGetSizeAndAlignment(const char *type, NSUInteger *sizep, NSUInteger *alignp) {
    NSInteger size = 0, align = 0;
    size = [FLEXTypeEncodingParser sizeForTypeEncoding:@(type) alignment:&align];
    
    if (size == -1) {
        return NO;
    }
    
    if (sizep) {
        *sizep = (NSUInteger)size;
    }
    
    if (alignp) {
        *alignp = (NSUInteger)size;
    }
    
    return YES;
}

@interface FLEXTypeEncodingParser ()
@property (nonatomic, readonly) NSScanner *scan;
@property (nonatomic, readonly) NSString *scanned;
@property (nonatomic, readonly) NSString *unscanned;

/// Replacements are made to this string as we scan as needed
@property (nonatomic) NSMutableString *cleaned;
/// Offset for \e further replacements to be made within \c cleaned
@property (nonatomic, readonly) NSUInteger cleanedReplacingOffset;
@end

@implementation FLEXTypeEncodingParser

- (NSString *)scanned {
    return [self.scan.string substringToIndex:self.scan.scanLocation];
}

- (NSString *)unscanned {
    return [self.scan.string substringFromIndex:self.scan.scanLocation];
}

#pragma mark Initialization

- (id)initWithObjCTypes:(NSString *)typeEncoding {
    self = [super init];
    if (self) {
        _scan = [NSScanner scannerWithString:typeEncoding];
        _scan.caseSensitive = YES;
        _cleaned = typeEncoding.mutableCopy;
    }

    return self;
}

#pragma mark Public

+ (BOOL)methodTypeEncodingSupported:(NSString *)typeEncoding cleaned:(NSString * __autoreleasing *)cleanedEncoding {
    FLEXTypeEncodingParser *parser = [[self alloc] initWithObjCTypes:typeEncoding];
    while (!parser.scan.isAtEnd) {
        if ([parser scanAndGetSizeAndAlignForNextType:nil] == -1) {
            return NO;
        }
    }
    
    if (cleanedEncoding) {
        *cleanedEncoding = parser.cleaned.copy;
    }
    
    return YES;
}

+ (NSString *)type:(NSString *)typeEncoding forMethodArgumentAtIndex:(NSUInteger)idx {
    FLEXTypeEncodingParser *parser = [[self alloc] initWithObjCTypes:typeEncoding];

    // Scan up to the argument we want
    for (NSUInteger i = 0; i < idx; i++) {
        if (![parser scanPastArg]) {
            [NSException raise:NSRangeException
                        format:@"Index %lu out of bounds for type encoding '%@'", idx, typeEncoding];
        }
    }

    return [parser scanArg];
}

+ (ssize_t)size:(NSString *)typeEncoding forMethodArgumentAtIndex:(NSUInteger)idx {
    return [self sizeForTypeEncoding:[self type:typeEncoding forMethodArgumentAtIndex:idx] alignment:nil];
}

+ (ssize_t)sizeForTypeEncoding:(NSString *)type alignment:(ssize_t *)alignOut {
    return [self sizeForTypeEncoding:type alignment:alignOut unaligned:NO];
}

+ (ssize_t)sizeForTypeEncoding:(NSString *)type alignment:(ssize_t *)alignOut unaligned:(BOOL)unaligned {
    ssize_t align = 0;
    ssize_t size = [[[self alloc] initWithObjCTypes:type] scanAndGetSizeAndAlignForNextType:&align];

    if (size == -1 || size == 0) {
        return size;
    }
    
    if (alignOut) {
        *alignOut = align;
    }

    if (unaligned) {
        return size;
    } else {
        size += size % align;
        return size;
    }
}

#pragma mark Private

- (NSCharacterSet *)identifierFirstCharCharacterSet {
    static NSCharacterSet *identifierFirstSet = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *allowed = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_$";
        identifierFirstSet = [NSCharacterSet characterSetWithCharactersInString:allowed];
    });
    
    return identifierFirstSet;
}

- (NSCharacterSet *)identifierCharacterSet {
    static NSCharacterSet *identifierSet = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *allowed = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_$1234567890";
        identifierSet = [NSCharacterSet characterSetWithCharactersInString:allowed];
    });
    
    return identifierSet;
}

/// For scanning struct/class names
- (NSString *)scanIdentifier {
    NSString *prefix = nil, *suffix = nil;
    
    // Identifiers cannot start with a number
    if (![self.scan scanCharactersFromSet:self.identifierFirstCharCharacterSet intoString:&prefix]) {
        return nil;
    }
    
    // Optional because identifier may just be one character
    [self.scan scanCharactersFromSet:self.identifierCharacterSet intoString:&suffix];
    
    if (suffix) {
        return [prefix stringByAppendingString:suffix];
    }
    
    return prefix;
}

/// Size in BYTES
- (ssize_t)sizeForType:(FLEXTypeEncoding)type {
    switch (type) {
        case FLEXTypeEncodingChar: return sizeof(char);
        case FLEXTypeEncodingInt: return sizeof(int);
        case FLEXTypeEncodingShort: return sizeof(short);
        case FLEXTypeEncodingLong: return sizeof(long);
        case FLEXTypeEncodingLongLong: return sizeof(long long);
        case FLEXTypeEncodingUnsignedChar: return sizeof(unsigned char);
        case FLEXTypeEncodingUnsignedInt: return sizeof(unsigned int);
        case FLEXTypeEncodingUnsignedShort: return sizeof(unsigned short);
        case FLEXTypeEncodingUnsignedLong: return sizeof(unsigned long);
        case FLEXTypeEncodingUnsignedLongLong: return sizeof(unsigned long long);
        case FLEXTypeEncodingFloat: return sizeof(float);
        case FLEXTypeEncodingDouble: return sizeof(double);
        case FLEXTypeEncodingLongDouble: return sizeof(long double);
        case FLEXTypeEncodingCBool: return sizeof(_Bool);
        case FLEXTypeEncodingVoid: return 0;
        case FLEXTypeEncodingCString: return sizeof(char *);
        case FLEXTypeEncodingObjcObject:  return sizeof(id);
        case FLEXTypeEncodingObjcClass:  return sizeof(Class);
        case FLEXTypeEncodingSelector: return sizeof(SEL);
        // Unknown / '?' is typically a pointer. In the rare case
        // it isn't, such as in '{?=...}', it is never passed here.
        case FLEXTypeEncodingUnknown:
        case FLEXTypeEncodingPointer: return sizeof(uintptr_t);

        default: return -1;
    }
}

/// Size in bytes
- (ssize_t)scanAndGetSizeAndAlignForNextType:(ssize_t *)alignment {
    NSUInteger start = self.scan.scanLocation;

    // Check for void first
    if ([self scanChar:FLEXTypeEncodingVoid]) {
        // Skip argument frame for method signatures
        [self scanSize];
        return 0;
    }

    // Scan optional const
    [self scanChar:FLEXTypeEncodingConst];

    // Check for pointer, then scan next
    if ([self scanChar:FLEXTypeEncodingPointer]) {
        // Recurse to scan something else
        NSUInteger pointerTypeStart = self.scan.scanLocation;
        if ([self scanPastArg]) {
            // Make sure the pointer type is supported, and clean it if not
            NSUInteger pointerTypeLength = self.scan.scanLocation - pointerTypeStart;
            NSString *pointerType = [self.scan.string
                substringWithRange:NSMakeRange(pointerTypeStart, pointerTypeLength)
            ];
            
            // Is it supported?
            if ([self.class sizeForTypeEncoding:pointerType alignment:nil] == -1) {
                // No, so clean it
                NSString *cleaned = [self cleanPointeeTypeAtLocation:pointerTypeStart];
                [self.cleaned replaceCharactersInRange:NSMakeRange(
                    pointerTypeStart - self.cleanedReplacingOffset, pointerTypeLength
                ) withString:cleaned];
            }
            
            // Skip optional frame offset
            [self scanSize];
            
            ssize_t size = [self sizeForType:FLEXTypeEncodingPointer];
            if (alignment) {
                *alignment = size;
            }
            return size;
        } else {
            // Scan failed, abort
            self.scan.scanLocation = start;
            return -1;
        }
    }

    // Check for struct/union/array
    if ([self canScanChar:FLEXTypeEncodingStructBegin] ||
      [self canScanChar:FLEXTypeEncodingUnionBegin] ||
      [self canScanChar:FLEXTypeEncodingArrayBegin]) {
        NSUInteger backup = self.scan.scanLocation;

        // Ensure we have a closing tag
        if (![self scanPair:FLEXTypeEncodingStructBegin close:FLEXTypeEncodingStructEnd] &&
          ![self scanPair:FLEXTypeEncodingUnionBegin close:FLEXTypeEncodingUnionEnd] &&
          ![self scanPair:FLEXTypeEncodingArrayBegin close:FLEXTypeEncodingArrayEnd]) {
            // Scan failed, abort
            self.scan.scanLocation = start;
            return -1;
        }

        // Scan the next thing until we scan the closing tag
        BOOL structOrUnion = NO, isUnion = NO;
        NSInteger arrayCount = -1;
        self.scan.scanLocation = backup;
        FLEXTypeEncoding closing;
        if ([self scanChar:FLEXTypeEncodingStructBegin]) {
            closing = FLEXTypeEncodingStructEnd;
            structOrUnion = YES;
        } else if ([self scanChar:FLEXTypeEncodingUnionBegin]) {
            closing = FLEXTypeEncodingUnionEnd;
            structOrUnion = isUnion = YES;
        } else {
            // Assert because code above did confirm a closing tag exists
            assert([self scanChar:FLEXTypeEncodingArrayBegin]);
            closing = FLEXTypeEncodingArrayEnd;
            
            arrayCount = [self scanSize];
            if (!arrayCount) {
                // Arrays must have a count after the opening brace
                self.scan.scanLocation = start;
                return -1;
            }
        }

        if (structOrUnion) {
            // If we encounter the ?= portion of something like {?=b8b4b1b1b18[8S]}
            // then we skip over it, since it means nothing to us in this context.
            // It is completely optional, and if it fails, we go right back where we were.
            [self scanTypeName];
        }

        // Sum sizes of members together:
        // Scan for bitfields before checking for other members
        //
        // Arrays will only have one "member," but
        // this logic still works for them
        ssize_t sizeSoFar = 0;
        ssize_t maxAlign = 0;
        NSMutableString *cleanedBackup = self.cleaned.mutableCopy;
        
        while (![self scanChar:closing]) {
            // Check for bitfields, which we cannot support because
            // type encodings for bitfields do not include alignment info
            if ([self scanChar:FLEXTypeEncodingBitField]) {
                self.scan.scanLocation = start;
                return -1;
            }

            // Structure fields could be named
            [self scanPair:FLEXTypeEncodingQuote close:FLEXTypeEncodingQuote];

            ssize_t align = 0;
            ssize_t size = [self scanAndGetSizeAndAlignForNextType:&align];
            if (size == -1) {
                // The above call is the only time in this method where
                // cleaned might be mutated recursively, so this is the
                // only place where we need to keep and restore a backup
                //
                // For instance, if we've been iterating over the members
                // of a struct and we've encountered a few pointers so far
                // that we needed to clean, and suddenly we come across
                // an unsupported member, we need to be able to "rewind"
                // and undo any chances to self.cleaned so that the parent
                // call in the call stack can wipe the current structure
                // clean entirely if needed. Example below:
                //
                //      Initial: ^{foo=^{pair<d,d>}{^pair<i,i>}{invalid_type<d>}}
                //                       v-- here
                //    1st clean: ^{foo=^{?=}{^pair<i,i>}{invalid_type<d>}
                //                          v-- here
                //    2nd clean: ^{foo=^{?=}{?=}{invalid_type<d>}
                //                             v-- here
                //  Can't clean: ^{foo=^{?=}{?=}{invalid_type<d>}
                //                 v-- to here
                //       Rewind: ^{foo=^{pair<d,d>}{^pair<i,i>}{invalid_type<d>}}
                //  Final clean: ^{foo=}
                self.cleaned = cleanedBackup;
                self.scan.scanLocation = start;
                return -1;
            }
            
            // Unions are the size of their largest member,
            // arrays are element.size x length, and
            // structs are the sum of their members
            if (structOrUnion) {
                if (isUnion) {
                    sizeSoFar = MAX(sizeSoFar, size);
                } else {
                    sizeSoFar += size;
                }
            } else {
                sizeSoFar = size * arrayCount;
            }
            
            maxAlign = MAX(maxAlign, align);
        }
        
        // Skip optional frame offset
        [self scanSize];

        if (alignment) {
            *alignment = maxAlign;
        }

        return sizeSoFar;
    }

    // Scan single thing and possible size and return
    ssize_t size = 0;
    FLEXTypeEncoding t;
    if ([self scanChar:FLEXTypeEncodingUnknown into:&t] ||
      [self scanChar:FLEXTypeEncodingChar into:&t] ||
      [self scanChar:FLEXTypeEncodingInt into:&t] ||
      [self scanChar:FLEXTypeEncodingShort into:&t] ||
      [self scanChar:FLEXTypeEncodingLong into:&t] ||
      [self scanChar:FLEXTypeEncodingLongLong into:&t] ||
      [self scanChar:FLEXTypeEncodingUnsignedChar into:&t] ||
      [self scanChar:FLEXTypeEncodingUnsignedInt into:&t] ||
      [self scanChar:FLEXTypeEncodingUnsignedShort into:&t] ||
      [self scanChar:FLEXTypeEncodingUnsignedLong into:&t] ||
      [self scanChar:FLEXTypeEncodingUnsignedLongLong into:&t] ||
      [self scanChar:FLEXTypeEncodingFloat into:&t] ||
      [self scanChar:FLEXTypeEncodingDouble into:&t] ||
      [self scanChar:FLEXTypeEncodingLongDouble into:&t] ||
      [self scanChar:FLEXTypeEncodingCBool into:&t] ||
      [self scanChar:FLEXTypeEncodingCString into:&t] ||
      [self scanChar:FLEXTypeEncodingSelector into:&t] ||
      [self scanChar:FLEXTypeEncodingBitField into:&t]) {
        // Skip optional frame offset
        [self scanSize];
        
        if (t == FLEXTypeEncodingBitField) {
            self.scan.scanLocation = start;
            return -1;
        } else {
            // Compute size
            size = [self sizeForType:t];
        }
    }

    // These might have numbers OR quotes after them
    else if ([self scanChar:FLEXTypeEncodingObjcObject] || [self scanChar:FLEXTypeEncodingObjcClass]) {
        // Skip optional frame offset
        [self scanSize];
        [self scanPair:FLEXTypeEncodingQuote close:FLEXTypeEncodingQuote];
        size = sizeof(id);
    }

    if (size) {
        // Alignment of scalar types is its size
        if (alignment) {
            *alignment = size;
        }

        return size;
    }

    self.scan.scanLocation = start;
    return -1;
}

- (BOOL)scanString:(NSString *)str {
    return [self.scan scanString:str intoString:nil];
}

- (BOOL)canScanString:(NSString *)str {
    if ([self scanString:str]) {
        self.scan.scanLocation -= str.length;
        return YES;
    }

    return NO;
}

- (BOOL)canScanChar:(char)c {
    return [self canScanString:S(c)];
}

- (BOOL)scanChar:(char)c {
    return [self scanString:S(c)];
}

- (BOOL)scanChar:(char)c into:(char *)ref {
    if ([self scanString:S(c)]) {
        *ref = c;
        return YES;
    }

    return NO;
}

- (ssize_t)scanSize {
    NSInteger size = 0;
    if ([self.scan scanInteger:&size]) {
        return size;
    }

    return 0;
}

- (NSString *)scanPair:(char)c1 close:(char)c2 {
    // Starting position and string variables
    NSUInteger start = self.scan.scanLocation;
    NSString *s1 = S(c1);

    // Scan opening tag
    if (![self scanChar:c1]) {
        self.scan.scanLocation = start;
        return nil;
    }

    // Character set for scanning up to either symbol
    NSCharacterSet *bothChars = ({
        unichar buff[2] = { c1, c2 };
        NSString *bothCharsStr = [[NSString alloc] initWithCharacters:buff length:2];
        [NSCharacterSet characterSetWithCharactersInString:bothCharsStr];
    });

    // Stack for finding pairs, starting with the opening symbol
    NSMutableArray *stack = [NSMutableArray arrayWithObject:s1];

    // Algorithm for scanning to the closing end of a pair of opening/closing symbols
    // scanUpToCharactersFromSet:intoString: returns NO if you're already at one of the chars,
    // so we need to check if we can actually scan one if it returns NO
    while ([self.scan scanUpToCharactersFromSet:bothChars intoString:nil] ||
           [self canScanChar:c1] || [self canScanChar:c2]) {
        // Closing symbol found
        if ([self scanChar:c2]) {
            if (!stack.count) {
                // Abort, no matching opening symbol
                self.scan.scanLocation = start;
                return nil;
            }

            // Pair found, pop opening symbol
            [stack removeLastObject];
            // Exit loop if we reached the closing brace we needed
            if (!stack.count) {
                break;
            }
        }
        // Opening symbol found
        if ([self scanChar:c1]) {
            // Begin pair
            [stack addObject:s1];
        }
    }

    if (stack.count) {
        // Abort, no matching closing symbol
        self.scan.scanLocation = start;
        return nil;
    }

    // Slice out the string we just scanned
    return [self.scan.string
        substringWithRange:NSMakeRange(start, self.scan.scanLocation - start)
    ];
}

- (BOOL)scanPastArg {
    NSUInteger start = self.scan.scanLocation;

    // Check for void first
    if ([self scanChar:FLEXTypeEncodingVoid]) {
        return YES;
    }

    // Scan optional const
    [self scanChar:FLEXTypeEncodingConst];

    // Check for pointer, then scan next
    if ([self scanChar:FLEXTypeEncodingPointer]) {
        // Recurse to scan something else
        if ([self scanPastArg]) {
            return YES;
        } else {
            // Scan failed, abort
            self.scan.scanLocation = start;
            return NO;
        }
    }

    // Check for struct/union/array, scan past it
    if ([self scanPair:FLEXTypeEncodingStructBegin close:FLEXTypeEncodingStructEnd] ||
      [self scanPair:FLEXTypeEncodingUnionBegin close:FLEXTypeEncodingUnionEnd] ||
      [self scanPair:FLEXTypeEncodingArrayBegin close:FLEXTypeEncodingArrayEnd]) {
        return YES;
    }

    // Scan single thing and possible size and return
    if ([self scanChar:FLEXTypeEncodingUnknown] ||
      [self scanChar:FLEXTypeEncodingChar] ||
      [self scanChar:FLEXTypeEncodingInt] ||
      [self scanChar:FLEXTypeEncodingShort] ||
      [self scanChar:FLEXTypeEncodingLong] ||
      [self scanChar:FLEXTypeEncodingLongLong] ||
      [self scanChar:FLEXTypeEncodingUnsignedChar] ||
      [self scanChar:FLEXTypeEncodingUnsignedInt] ||
      [self scanChar:FLEXTypeEncodingUnsignedShort] ||
      [self scanChar:FLEXTypeEncodingUnsignedLong] ||
      [self scanChar:FLEXTypeEncodingUnsignedLongLong] ||
      [self scanChar:FLEXTypeEncodingFloat] ||
      [self scanChar:FLEXTypeEncodingDouble] ||
      [self scanChar:FLEXTypeEncodingLongDouble] ||
      [self scanChar:FLEXTypeEncodingCBool] ||
      [self scanChar:FLEXTypeEncodingCString] ||
      [self scanChar:FLEXTypeEncodingSelector] ||
      [self scanChar:FLEXTypeEncodingBitField]) {
        // Size is optional
        [self scanSize];
        return YES;
    }

    // These might have numbers OR quotes after them
    if ([self scanChar:FLEXTypeEncodingObjcObject] || [self scanChar:FLEXTypeEncodingObjcClass]) {
        [self scanSize] || [self scanPair:FLEXTypeEncodingQuote close:FLEXTypeEncodingQuote];
        return YES;
    }

    self.scan.scanLocation = start;
    return NO;
}

- (NSString *)scanArg {
    NSUInteger start = self.scan.scanLocation;
    if (![self scanPastArg]) {
        return nil;
    }

    return [self.scan.string
        substringWithRange:NSMakeRange(start, self.scan.scanLocation - start)
    ];
}

- (BOOL)scanTypeName {
    NSUInteger start = self.scan.scanLocation;

    // The ?= portion of something like {?=b8b4b1b1b18[8S]}
    if ([self scanChar:FLEXTypeEncodingUnknown]) {
        if (![self scanString:@"="]) {
            // No size information available for strings like {?=}
            self.scan.scanLocation = start;
            return NO;
        }
    } else {
        if (![self scanIdentifier] || ![self scanString:@"="]) {
            // 1. Not a valid identifier
            // 2. No size information available for strings like {CGPoint}
            self.scan.scanLocation = start;
            return NO;
        }
    }

    return YES;
}

- (NSString *)extractTypeNameFromScanLocation {
    NSUInteger start = self.scan.scanLocation;
    NSString *typeName = nil;

    // The ?= portion of something like {?=b8b4b1b1b18[8S]}
    if ([self scanChar:FLEXTypeEncodingUnknown]) {
        typeName = @"?";
    } else {
        typeName = [self scanIdentifier];
        // = is non-optional
        if (!typeName || ![self scanString:@"="]) {
            // Did not scan an identifier
            self.scan.scanLocation = start;
            return nil;
        }
    }

    return typeName;
}

- (NSString *)cleanPointeeTypeAtLocation:(NSUInteger)scanLocation {
    NSUInteger start = self.scan.scanLocation;
    self.scan.scanLocation = scanLocation;
    
    // The return / cleanup code for when the scanned type is already clean
    NSString * (^typeIsClean)() = ^NSString * {
        NSString *clean = [self.scan.string
            substringWithRange:NSMakeRange(scanLocation, self.scan.scanLocation - scanLocation)
        ];
        // Reset scan location even on success, because this method is not supposed to change it
        self.scan.scanLocation = start;
        return clean;
    };

    // No void, this is not a return type

    // Scan optional const
    [self scanChar:FLEXTypeEncodingConst];

    // Check for pointer, then scan next
    if ([self scanChar:FLEXTypeEncodingPointer]) {
        // Recurse to scan something else
        return [self cleanPointeeTypeAtLocation:self.scan.scanLocation];
    }
    
    // All arrays are supported, scan past them
    if ([self scanPair:FLEXTypeEncodingArrayBegin close:FLEXTypeEncodingArrayEnd]) {
        return typeIsClean();
    }

    // Check for struct/union
    if ([self canScanChar:FLEXTypeEncodingStructBegin] || [self canScanChar:FLEXTypeEncodingUnionBegin]) {
        if ([self scanAndGetSizeAndAlignForNextType:nil] != -1) {
            return typeIsClean();
        }
        
        // The structure we just tried to scan is unsupported, so just return its name
        // if it has one. If not, just return a question mark.
        BOOL isStruct = [self scanChar:FLEXTypeEncodingStructBegin];
        BOOL isUnion = [self scanChar:FLEXTypeEncodingUnionBegin];
        assert(isStruct || isUnion);
        
        NSString *open = isStruct ? @"{" : @"(";
        NSString *close = isStruct ? @"}" : @")";
        char closec = isStruct ? FLEXTypeEncodingStructEnd : FLEXTypeEncodingUnionEnd;
        
        NSString *name = [self extractTypeNameFromScanLocation];
        if (name) {
            // Got the name, scan past the closing token
            [self.scan scanUpToString:close intoString:nil];
            if (![self scanChar:closec]) {
                // Missing struct/union close token
                self.scan.scanLocation = start;
                return nil;
            }
        } else {
            // Did not scan valid identifier, possibly a C++ type
            self.scan.scanLocation = start;
            return @"{?=}";
        }
        
        // Reset scan location even on success, because this method is not supposed to change it
        self.scan.scanLocation = start;
        return [NSString stringWithFormat:@"%@%@=%@", open, name, close];
    }
    
    // Check for other types, which in theory are all valid but whatever
    if ([self scanAndGetSizeAndAlignForNextType:nil] != -1) {
        return typeIsClean();
    }
    
    self.scan.scanLocation = start;
    return @"{?=}";
}

- (NSUInteger)cleanedReplacingOffset {
    return self.scan.string.length - self.cleaned.length;
}

@end
