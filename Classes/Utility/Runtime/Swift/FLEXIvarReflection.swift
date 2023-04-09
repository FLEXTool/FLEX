//
//  FLEXIvarReflection.swift
//  FLEX
//
//  Created by Natheer on 10/04/2023.
//  Copyright © 2023 Flipboard. All rights reserved.
//

import Foundation

@objc public class FLEXIvarReflection : NSObject {
    @objc public static func reflection(on obj: AnyObject, ivar: String) -> AnyObject? {
        let ObjMirror = Mirror(reflecting: obj)
        for child in ObjMirror.children {
            if child.label == ivar {
                return child as AnyObject
            }
        }
        return nil
    }
}
