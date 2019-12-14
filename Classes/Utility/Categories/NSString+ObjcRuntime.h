//
//  NSString+ObjcRuntime.h
//  FLEX
//
//  Derived from MirrorKit.
//  Created by Tanner on 7/1/15.
//  Copyright (c) 2015 Tanner Bennett. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Utilities)

/// A dictionary of property attributes if the receiver is a valid property attributes string.
/// Values are either a string or \c @YES. Boolean attributes which are false will not be
/// present in the dictionary. See this link on how to construct a proper attributes string:
/// https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html
- (NSDictionary *)propertyAttributes;

@end
