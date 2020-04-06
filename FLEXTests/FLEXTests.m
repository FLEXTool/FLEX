//
//  FLEXTests.m
//  FLEXTests
//
//  Created by Tanner Bennett on 8/27/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <objc/runtime.h>
#import "NSObject+FLEX_Reflection.h"
#import "NSArray+FLEX.h"
#import "FLEXPropertyAttributes.h"
#import "FLEXProperty.h"
#import "FLEXUtility.h"
#import "FLEXMethod.h"

@interface Subclass : NSObject @end
@implementation Subclass @end

@interface FLEXTests : XCTestCase
@property (nonatomic, setter=setMyFoo:) id foo;
@end

@implementation FLEXTests

- (void)testRuntimeAdditions {
    XCTAssertEqual(1, NSObject.flex_classHierarchy.count);
    XCTAssertEqual(4, FLEXTests.flex_classHierarchy.count);
    XCTAssertEqual(FLEXTests.flex_classHierarchy.firstObject, [self class]);
    XCTAssertEqual(FLEXTests.flex_classHierarchy.lastObject, [NSObject class]);
}

- (void)testAssumptionsAboutClasses {
    Class cls = [self class];
    Class meta = objc_getMetaClass(NSStringFromClass(cls).UTF8String);

    // Subsequent `class` calls yield self
    XCTAssertEqual(cls, [cls class]);
    XCTAssertEqual(meta, [meta class]);
    // A class's superclass is NOT a metaclass
    XCTAssertFalse(class_isMetaClass([cls superclass]));
    // A metaclass's superclass IS a metaclass
    XCTAssertTrue(class_isMetaClass([meta superclass]));

    // Subsequent object_getClass calls yield metaclass
    XCTAssertEqual(object_getClass(cls), meta);
    XCTAssertEqual(object_getClass(meta), meta);

    // Superclass of a root class is nil
    XCTAssertNil(NSObject.superclass);
}

- (void)testAssumptionsAboutMessageSending {
    // "instances respond to selector" works with metaclasses targeting class objects
    Class meta = object_getClass(NSBundle.class);
    XCTAssertTrue([meta instancesRespondToSelector:@selector(mainBundle)]);
    XCTAssertFalse([meta respondsToSelector:@selector(mainBundle)]);
}

- (void)testAssumptionsAboutRuntimeMethodFunctions {
    Class cls = [NSBundle class];
    Class meta = object_getClass(cls);

    Method bundleID = class_getInstanceMethod(cls, @selector(bundleIdentifier));
    Method mainBundle = class_getClassMethod(cls, @selector(mainBundle));

    // Preconditions...
    XCTAssert(class_isMetaClass(meta));
    XCTAssert(bundleID != nil);
    XCTAssert(mainBundle != nil);

    // Metaclasses cannot find instance methods
    XCTAssertEqual(nil, class_getInstanceMethod(meta, @selector(bundleIdentifier)));
    // Metaclasses can find class methods as both class methods and instance methods,
    // and the methods found by metaclasses are equal regardless of which function is used
    XCTAssertEqual(mainBundle, class_getClassMethod(meta, @selector(mainBundle)));
    // Metaclasses can find class methods as instance methods
    XCTAssertEqual(mainBundle, class_getInstanceMethod(meta, @selector(mainBundle)));
}

- (void)testAbilitiesOfKVC {
    [self setValue:@5 forKey:@"foo"];
    XCTAssertEqualObjects(self.foo, @5);
}

- (void)testCPPTypeEncoding {
    const char *type = "{basic_string<char, std::__1::char_traits<char>, "
    "std::__1::allocator<char> >={__compressed_pair<std::__1::basic_string<char, "
    "std::__1::char_traits<char>, std::__1::allocator<char> >::__rep, "
    "std::__1::allocator<char> >={__rep}}}";

    XCTAssertThrows(NSGetSizeAndAlignment(type, nil, nil));
}

- (void)testGetClassProperties {
    NSArray *props = NSBundle.flex_allClassProperties;
    props = [props flex_filtered:^BOOL(FLEXProperty *obj, NSUInteger idx) {
        return [obj.name isEqualToString:@"mainBundle"];
    }];
    XCTAssert(props.count == 1);
}

@end
