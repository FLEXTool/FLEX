//
//  FLEXIvar.h
//  FLEX
//
//  Derived from MirrorKit.
//  Created by Tanner on 6/30/15.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXRuntimeConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface FLEXIvar : NSObject

+ (instancetype)ivar:(Ivar)ivar;
+ (instancetype)named:(NSString *)name onClass:(Class)cls;

/// The underlying \c Ivar data structure.
@property (nonatomic, readonly) Ivar             objc_ivar;

/// The name of the instance variable.
@property (nonatomic, readonly) NSString         *name;
/// The type of the instance variable.
@property (nonatomic, readonly) FLEXTypeEncoding type;
/// The type encoding string of the instance variable.
@property (nonatomic, readonly) NSString         *typeEncoding;
/// The offset of the instance variable.
@property (nonatomic, readonly) NSInteger        offset;
/// The size of the instance variable. 0 if unknown.
@property (nonatomic, readonly) NSUInteger       size;
/// Describes the type encoding, size, offset, and objc_ivar
@property (nonatomic, readonly) NSString        *details;
/// The full path of the image that contains this ivar definition,
/// or \c nil if this ivar was probably defined at runtime.
@property (nonatomic, readonly, nullable) NSString *imagePath;

/// For internal use
@property (nonatomic) id tag;

- (nullable id)getValue:(id)target;
- (void)setValue:(nullable id)value onObject:(id)target;

/// Calls into -getValue: and passes that value into
/// -[FLEXRuntimeUtility potentiallyUnwrapBoxedPointer:type:]
/// and returns the result
- (nullable id)getPotentiallyUnboxedValue:(id)target;

@end

NS_ASSUME_NONNULL_END
