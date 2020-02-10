//
//  FLEXSwiftTests.m
//  FLEXTests
//
//  Created by Tanner on 2/10/20.
//  Copyright © 2020 Flipboard. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Metadata.h"
#import "SwiftExports.h"
#import "FLEXTests-Swift.h"

@interface FLEXSwiftTests : XCTestCase
@property (nonatomic, readonly) Class personClass;
@end

@implementation FLEXSwiftTests

- (void)setUp {
    _personClass = NSClassFromString(@"FLEXTests.Person");
}

- (void)testPersonExists {
    XCTAssertNotNil(self.personClass);
}

- (void)testPerson {
    uint32_t size = (uint32_t)class_getInstanceSize(self.personClass);
    id person = swift_allocObject(self.personClass, size, alignof(void *));
    NSString *name = getObjectClassName(person);
    XCTAssertEqualObjects(name, @"Person");
}

@end
