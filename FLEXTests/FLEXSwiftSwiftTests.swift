//
//  FLEXSwiftSwiftTests.swift
//  FLEXTests
//
//  Created by Tanner on 2/10/20.
//  Copyright © 2020 Flipboard. All rights reserved.
//

import XCTest

class FLEXSwiftSwiftTests: XCTestCase {

    func testSwiftClassKind() {
        let str = NSStringFromClass(Person.self)
        let cls = NSClassFromString("FLEXTests.Person")
        XCTAssertNotEqual(metadataPointer(type: Person.self).pointee, 0)
    }
}
