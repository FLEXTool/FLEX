//
//  FLEXBlockDescription.h
//  FLEX
//
//  Created by Oliver Letterer on 2012-09-01
//  Forked from CTObjectiveCRuntimeAdditions (MIT License)
//  https://github.com/ebf/CTObjectiveCRuntimeAdditions
//
//  Copyright (c) 2020 FLEX Team-EDV Beratung Föllmer GmbH
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this
//  software and associated documentation files (the "Software"), to deal in the Software
//  without restriction, including without limitation the rights to use, copy, modify, merge,
//  publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons
//  to whom the Software is furnished to do so, subject to the following conditions:
//  The above copyright notice and this permission notice shall be included in all copies or
//  substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
//  BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
//  DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, FLEXBlockOptions) {
   FLEXBlockOptionHasCopyDispose = (1 << 25),
   FLEXBlockOptionHasCtor        = (1 << 26), // helpers have C++ code
   FLEXBlockOptionIsGlobal       = (1 << 28),
   FLEXBlockOptionHasStret       = (1 << 29), // IFF BLOCK_HAS_SIGNATURE
   FLEXBlockOptionHasSignature   = (1 << 30),
};

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
@interface FLEXBlockDescription : NSObject

+ (instancetype)describing:(id)block;

@property (nonatomic, readonly, nullable) NSMethodSignature *signature;
@property (nonatomic, readonly, nullable) NSString *signatureString;
@property (nonatomic, readonly, nullable) NSString *sourceDeclaration;
@property (nonatomic, readonly) FLEXBlockOptions flags;
@property (nonatomic, readonly) NSUInteger size;
@property (nonatomic, readonly) NSString *summary;
@property (nonatomic, readonly) id block;

- (BOOL)isCompatibleForBlockSwizzlingWithMethodSignature:(NSMethodSignature *)methodSignature;

@end

#pragma mark -
@interface NSBlock : NSObject
- (void)invoke;
@end

NS_ASSUME_NONNULL_END
