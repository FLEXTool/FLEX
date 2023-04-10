//
//  NSObject+IvarReflection.swift
//  FLEX
//
//  Created by Natheer on 10/04/2023.
//  Copyright © 2023 Flipboard. All rights reserved.
//

import Foundation


@objc public extension NSObject {
    @objc func reflectIvarNamed(_ name: String) -> Any? {
        Mirror(reflecting: self)
            .children
            .first(where: {$0.label == name})
            .map(\.value)
    }
}
