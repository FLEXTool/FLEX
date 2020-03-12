//
//  FLEXProtocol.h
//  FLEX
//
//  Derived from MirrorKit.
//  Created by Tanner on 6/30/15.
//  Copyright (c) 2015 Tanner Bennett. All rights reserved.
//

#import "FLEXRuntimeConstants.h"
@class FLEXProperty, FLEXMethodDescription;

#pragma mark FLEXProtocol
@interface FLEXProtocol : NSObject

/// Every protocol registered with the runtime.
+ (NSArray<FLEXProtocol *> *)allProtocols;
+ (instancetype)protocol:(Protocol *)protocol;

/// The underlying protocol data structure.
@property (nonatomic, readonly) Protocol *objc_protocol;

/// The name of the protocol.
@property (nonatomic, readonly) NSString *name;
/// The properties in the protocol, if any.
@property (nonatomic, readonly) NSArray<FLEXProperty *>  *properties;
/// The required methods of the protocol, if any. This includes property getters and setters.
@property (nonatomic, readonly) NSArray<FLEXMethodDescription *>  *requiredMethods;
/// The optional methods of the protocol, if any. This includes property getters and setters.
@property (nonatomic, readonly) NSArray<FLEXMethodDescription *>  *optionalMethods;
/// All protocols that this protocol conforms to, if any.
@property (nonatomic, readonly) NSArray<FLEXProtocol *>  *protocols;

/// For internal use
@property (nonatomic) id tag;

/// Not to be confused with \c -conformsToProtocol:, which refers to the current
/// \c FLEXProtocol instance and not the underlying \c Protocol object.
- (BOOL)conformsTo:(Protocol *)protocol;

@end


#pragma mark Method descriptions
@interface FLEXMethodDescription : NSObject

+ (instancetype)description:(struct objc_method_description)methodDescription;

/// The underlying method description data structure.
@property (nonatomic, readonly) struct objc_method_description objc_description;
/// The method's selector.
@property (nonatomic, readonly) SEL selector;
/// The method's type encoding.
@property (nonatomic, readonly) NSString *typeEncoding;
/// The method's return type.
@property (nonatomic, readonly) FLEXTypeEncoding returnType;
@end
