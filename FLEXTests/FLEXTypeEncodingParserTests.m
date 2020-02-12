//
//  FLEXTypeEncodingParserTests.m
//  FLEXTests
//
//  Created by Tanner Bennett on 8/25/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import "FLEXTypeEncodingParser.h"

#define Type(t) @(@encode(t))
#define TypeSizeAlignPair(t) Type(t): @[@(sizeof(t)), @(__alignof__(t))]

@interface FLEXTypeEncodingParserTests : XCTestCase {
    struct {
        id __unsafe_unretained *bar;
        void (*foo[5])(void);
        SEL abc;
        Class cls;
        int baz;
        NSString * __unsafe_unretained str;
        id<NSCopying, NSCoding> __unsafe_unretained proto;
        NSDictionary<NSCopying, NSCoding> * __unsafe_unretained another;
    } _yikes;
}

@property (nonatomic, readonly) NSDictionary<NSString *, NSArray<NSNumber *> *> *typesToSizes;
@end

typedef struct Anon {
    NSString<NSCopying,NSCoding> *bar;
    int baz;
} Anon;

@implementation FLEXTypeEncodingParserTests

- (void)setUp {
    
    memset(&_yikes.bar, 0x55, sizeof(id));
    memset(&_yikes.foo, 0xff, sizeof(_yikes.foo));
    memset(&_yikes.abc, 0x88, sizeof(SEL));
    
    _typesToSizes = @{
        TypeSizeAlignPair(__typeof__(_yikes)),
        @"{Anon=\"bar\"@\"NSString<NSCopying><NSCoding>\"\"baz\"i}" : @[@(sizeof(Anon)), @(__alignof__(Anon))],
        Type(NSDecimal) : @[@-1, @0], // Real size is 16 on 64 bit machines
        TypeSizeAlignPair(char),
        TypeSizeAlignPair(short),
        TypeSizeAlignPair(int),
        TypeSizeAlignPair(long),
        TypeSizeAlignPair(long long),
        TypeSizeAlignPair(float),
        TypeSizeAlignPair(double),
        TypeSizeAlignPair(long double),
        TypeSizeAlignPair(Class),
        TypeSizeAlignPair(id),
        TypeSizeAlignPair(CGPoint),
        TypeSizeAlignPair(CGRect),
        TypeSizeAlignPair(char *),
        TypeSizeAlignPair(long *),
        TypeSizeAlignPair(Class *),
        TypeSizeAlignPair(CGRect *)
    };
}

- (void)testTypeEncodingParser {
    [self.typesToSizes enumerateKeysAndObjectsUsingBlock:^(NSString *typeString, NSArray<NSNumber *> *sa, BOOL *stop) {
        if (sa[0].longLongValue >= 0) {
            XCTAssertNoThrow(NSGetSizeAndAlignment(typeString.UTF8String, nil, nil));
        } else {
            XCTAssertThrows(NSGetSizeAndAlignment(typeString.UTF8String, nil, nil));
        }
        
        ssize_t align = 0;
        ssize_t size = [FLEXTypeEncodingParser sizeForTypeEncoding:typeString alignment:&align];
        XCTAssertEqual(size, sa[0].longValue);
        XCTAssertEqual(align, sa[1].longValue);
    }];
}

- (void)testExpectedStructureSizes {
    typedef struct _FooBytes {
        uint8_t x: 3;
        struct {
            uint8_t a: 1;
            uint8_t b: 2;
        } y;
        uint8_t z: 5;
    } FooBytes;

    typedef struct _FooInts {
        unsigned int x: 3;
        struct {
            unsigned int a: 1;
            unsigned int b: 2;
        } y;
        unsigned int z: 5;
    } FooInts;

    typedef struct _Bar {
        unsigned int x: 3;
        unsigned int z: 5;
        struct {
            unsigned int a: 1;
            unsigned int b: 2;
        } y;
    } Bar;

    typedef struct _ArrayInMiddle {
        unsigned int x: 3;
        unsigned char c[2];
        unsigned int z: 5;
    } ArrayInMiddle;
    typedef struct _ArrayAtEnd {
        unsigned int x: 3;
        unsigned int z: 5;
        unsigned char c[2];
    } ArrayAtEnd;

    typedef struct _OneBit {
        uint8_t x: 1;
    } OneBit;
    typedef struct _OneByte {
        uint8_t x;
    } OneByte;
    typedef struct _TwoBytes {
        uint8_t x, y;
    } TwoBytes;
    typedef struct _TwoJoinedBytesAndOneByte {
        uint16_t x;
        uint8_t y;
    } TwoJoinedBytesAndOneByte;

    // Structs have the alignment of the size of their smallest member, recursively.
    // That is, a struct has the alignment of the greater of the size of its
    // largest direct member or the largest alignment of it's nested structs.
    XCTAssertEqual(__alignof__(FooBytes), 1);
    XCTAssertEqual(__alignof__(FooInts), 4);
    XCTAssertEqual(__alignof__(ArrayInMiddle), 4);
    XCTAssertEqual(__alignof__(ArrayAtEnd), 4);
    XCTAssertEqual(__alignof__(OneBit), 1);
    XCTAssertEqual(__alignof__(OneByte), 1);
    XCTAssertEqual(__alignof__(TwoBytes), 1);
    XCTAssertEqual(__alignof__(TwoJoinedBytesAndOneByte), 2);

    // Nested structs are aligned before and after, if between bitfields
    XCTAssertEqual(sizeof(FooBytes), 3);
    XCTAssertEqual(sizeof(FooInts), 12);
    // Bitfields are not aligned at all and they will pack if adjacent to one another
    XCTAssertEqual(sizeof(Bar), 8);
    // Structs are resized to match their alignment
    XCTAssertEqual(sizeof(OneBit), 1);
    XCTAssertEqual(sizeof(OneByte), 1);
    XCTAssertEqual(sizeof(TwoJoinedBytesAndOneByte), 4);
    // Arrays do not affect alignment like nested structs do
    XCTAssertEqual(sizeof(ArrayInMiddle), 4);
    XCTAssertEqual(sizeof(ArrayAtEnd), 4);

    // Test my method of converting calculated sizes to actual sizes
    // for FLEXTypeEncodingParser
    #define RoundUpToMultipleOf4(num) ((num + 3) & ~0x03)
    XCTAssertEqual(RoundUpToMultipleOf4(1), 4);
    XCTAssertEqual(RoundUpToMultipleOf4(2), 4);
    XCTAssertEqual(RoundUpToMultipleOf4(3), 4);
    XCTAssertEqual(RoundUpToMultipleOf4(4), 4);
    XCTAssertEqual(RoundUpToMultipleOf4(5), 8);
    XCTAssertEqual(RoundUpToMultipleOf4(6), 8);
    XCTAssertEqual(RoundUpToMultipleOf4(7), 8);
    XCTAssertEqual(RoundUpToMultipleOf4(8), 8);
    XCTAssertEqual(RoundUpToMultipleOf4(9), 12);
    XCTAssertEqual(RoundUpToMultipleOf4(10), 12);
    XCTAssertEqual(RoundUpToMultipleOf4(11), 12);
    XCTAssertEqual(RoundUpToMultipleOf4(12), 12);
    XCTAssertEqual(RoundUpToMultipleOf4(13), 16);
}

- (void)testMethodSignatures {
    NSArray<NSString *> *signatures = @[
        @"^{__CFBundle=}16@0:8", @"v24@0:8@16", @"@40@0:8@16{CGSize=dd}24"
    ];
    
    for (NSString *signature in signatures) {
        XCTAssertTrue([FLEXTypeEncodingParser methodTypeEncodingSupported:signature]);
    }
}

@end
