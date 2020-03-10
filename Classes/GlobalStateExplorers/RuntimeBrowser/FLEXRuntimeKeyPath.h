//
//  FLEXRuntimeKeyPath.h
//  FLEX
//
//  Created by Tanner on 3/22/17.
//  Copyright © 2017 Tanner Bennett. All rights reserved.
//

#import "FLEXSearchToken.h"
@class FLEXMethod;

NS_ASSUME_NONNULL_BEGIN

/// A key path represents a query into a set of bundles or classes
/// for a set of one or more methods. It is composed of three tokens:
/// bundle, class, and method. A key path may be incomplete if it
/// is missing any of the tokens. A key path is considered "absolute"
/// if all tokens have no options and if methodKey.string begins
/// with a + or a -.
///
/// The @code TBKeyPathTokenizer @endcode class is used to create
/// a key path from a string.
@interface FLEXRuntimeKeyPath : NSObject

+ (instancetype)empty;

/// @param method must start with either a wildcard or a + or -.
+ (instancetype)bundle:(FLEXSearchToken *)bundle
                 class:(FLEXSearchToken *)cls
                method:(FLEXSearchToken *)method
            isInstance:(NSNumber *)instance
                string:(NSString *)keyPathString;

@property (nonatomic, nullable, readonly) FLEXSearchToken *bundleKey;
@property (nonatomic, nullable, readonly) FLEXSearchToken *classKey;
@property (nonatomic, nullable, readonly) FLEXSearchToken *methodKey;

/// Indicates whether the method token specifies instance methods.
/// Nil if not specified.
@property (nonatomic, nullable, readonly) NSNumber *instanceMethods;

@end
NS_ASSUME_NONNULL_END
