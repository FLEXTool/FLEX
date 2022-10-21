//
//  FLEXProtocol.h
//  FLEX
//
//  Derived from MirrorKit.
//  Created by Tanner on 6/30/15.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXRuntimeConstants.h"
@class FLEXProperty, FLEXMethodDescription;

NS_ASSUME_NONNULL_BEGIN

#pragma mark FLEXProtocol
@interface FLEXProtocol : NSObject

/// Every protocol registered with the runtime.
+ (NSArray<FLEXProtocol *> *)allProtocols;
+ (instancetype)protocol:(Protocol *)protocol;

/// The underlying protocol data structure.
@property (nonatomic, readonly) Protocol *objc_protocol;

/// The name of the protocol.
@property (nonatomic, readonly) NSString *name;
/// The required methods of the protocol, if any. This includes property getters and setters.
@property (nonatomic, readonly) NSArray<FLEXMethodDescription *> *requiredMethods;
/// The optional methods of the protocol, if any. This includes property getters and setters.
@property (nonatomic, readonly) NSArray<FLEXMethodDescription *> *optionalMethods;
/// All protocols that this protocol conforms to, if any.
@property (nonatomic, readonly) NSArray<FLEXProtocol *> *protocols;
/// The full path of the image that contains this protocol definition,
/// or \c nil if this protocol was probably defined at runtime.
@property (nonatomic, readonly, nullable) NSString *imagePath;

/// The properties in the protocol, if any. \c nil on iOS 10+ 
@property (nonatomic, readonly, nullable) NSArray<FLEXProperty *> *properties API_DEPRECATED("Use the more specific accessors below", ios(2.0, 10.0));

/// The required properties in the protocol, if any.
@property (nonatomic, readonly) NSArray<FLEXProperty *> *requiredProperties API_AVAILABLE(ios(10.0));
/// The optional properties in the protocol, if any.
@property (nonatomic, readonly) NSArray<FLEXProperty *> *optionalProperties API_AVAILABLE(ios(10.0));

/// For internal use
@property (nonatomic) id tag;

/// Not to be confused with \c -conformsToProtocol:, which refers to the current
/// \c FLEXProtocol instance and not the underlying \c Protocol object.
- (BOOL)conformsTo:(Protocol *)protocol;

@end


#pragma mark Method descriptions
@interface FLEXMethodDescription : NSObject

+ (instancetype)description:(struct objc_method_description)description;
+ (instancetype)description:(struct objc_method_description)description instance:(BOOL)isInstance;

/// The underlying method description data structure.
@property (nonatomic, readonly) struct objc_method_description objc_description;
/// The method's selector.
@property (nonatomic, readonly) SEL selector;
/// The method's type encoding.
@property (nonatomic, readonly) NSString *typeEncoding;
/// The method's return type.
@property (nonatomic, readonly) FLEXTypeEncoding returnType;
/// \c YES if this is an instance method, \c NO if it is a class method, or \c nil if unspecified
@property (nonatomic, readonly) NSNumber *instance;
@end

NS_ASSUME_NONNULL_END
