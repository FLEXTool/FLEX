//
//  FLEXSearchToken.h
//  FLEX
//
//  Created by Tanner on 3/22/17.
//  Copyright © 2017 Tanner Bennett. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, TBWildcardOptions) {
    TBWildcardOptionsNone   = 0,
    TBWildcardOptionsAny    = 1,
    TBWildcardOptionsPrefix = 1 << 1,
    TBWildcardOptionsSuffix = 1 << 2,
};

/// A token may contain wildcards at one or either end,
/// but not in the middle of the token (as of now).
@interface FLEXSearchToken : NSObject

+ (instancetype)any;
+ (instancetype)string:(NSString *)string options:(TBWildcardOptions)options;

/// Will not contain the wildcard (*) symbol
@property (nonatomic, readonly) NSString *string;
@property (nonatomic, readonly) TBWildcardOptions options;

/// Opposite of "is ambiguous"
@property (nonatomic, readonly) BOOL isAbsolute;
@property (nonatomic, readonly) BOOL isAny;
/// Still \c isAny, but checks that the string is empty
@property (nonatomic, readonly) BOOL isEmpty;

@end
