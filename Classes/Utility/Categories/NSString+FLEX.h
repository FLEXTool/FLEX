//
//  NSString+FLEX.h
//  FLEX
//
//  Created by Tanner on 3/26/17.
//  Copyright © 2017 Tanner Bennett. All rights reserved.
//

#import "FLEXRuntimeConstants.h"

@interface NSString (FLEXTypeEncoding)

///@return whether this type starts with the const specifier
@property (nonatomic, readonly) BOOL flex_typeIsConst;
/// @return the first char in the type encoding that is not the const specifier
@property (nonatomic, readonly) FLEXTypeEncoding flex_firstNonConstType;
/// @return the first char in the type encoding after the pointer specifier, if it is a pointer
@property (nonatomic, readonly) FLEXTypeEncoding flex_pointeeType;
/// @return whether this type is an objc object of any kind, even if it's const
@property (nonatomic, readonly) BOOL flex_typeIsObjectOrClass;
/// @return the class named in this type encoding if it is of the form \c @"MYClass"
@property (nonatomic, readonly) Class flex_typeClass;
/// Includes C strings and selectors as well as regular pointers
@property (nonatomic, readonly) BOOL flex_typeIsNonObjcPointer;

@end

@interface NSString (KeyPaths)

- (NSString *)stringByRemovingLastKeyPathComponent;
- (NSString *)stringByReplacingLastKeyPathComponent:(NSString *)replacement;

@end
