//
//  FLEXMethodBase.h
//  FLEX
//
//  Derived from MirrorKit.
//  Created by Tanner on 7/5/15.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import <Foundation/Foundation.h>


/// A base class for methods which encompasses those that may not
/// have been added to a class yet. Useful on it's own for adding
/// methods to a class, or building a new class from the ground up.
@interface FLEXMethodBase : NSObject {
@protected
    SEL      _selector;
    NSString *_name;
    NSString *_typeEncoding;
    IMP      _implementation;
    
    NSString *_flex_description;
}

/// Constructs and returns a \c FLEXSimpleMethod instance with the given name, type encoding, and implementation.
+ (instancetype)buildMethodNamed:(NSString *)name withTypes:(NSString *)typeEncoding implementation:(IMP)implementation;

/// The selector of the method.
@property (nonatomic, readonly) SEL      selector;
/// The selector string of the method.
@property (nonatomic, readonly) NSString *selectorString;
/// Same as selectorString.
@property (nonatomic, readonly) NSString *name;
/// The type encoding of the method.
@property (nonatomic, readonly) NSString *typeEncoding;
/// The implementation of the method.
@property (nonatomic, readonly) IMP      implementation;

/// For internal use
@property (nonatomic) id tag;

@end
