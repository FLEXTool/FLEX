//
//  FLEXMirror.h
//  FLEX
//
//  Derived from MirrorKit.
//  Created by Tanner on 6/29/15.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
@class FLEXMethod, FLEXProperty, FLEXIvar, FLEXProtocol;

NS_ASSUME_NONNULL_BEGIN

#pragma mark FLEXMirror Protocol
NS_SWIFT_NAME(FLEXMirrorProtocol)
@protocol FLEXMirror <NSObject>

/// Swift initializer
/// @throws If a metaclass object is passed in.
- (instancetype)initWithSubject:(id)objectOrClass NS_SWIFT_NAME(init(reflecting:));

/// The underlying object or \c Class used to create this \c FLEXMirror.
@property (nonatomic, readonly) id   value;
/// Whether \c value was a class or a class instance.
@property (nonatomic, readonly) BOOL isClass;
/// The name of the \c Class of the \c value property.
@property (nonatomic, readonly) NSString *className;

@property (nonatomic, readonly) NSArray<FLEXProperty *> *properties;
@property (nonatomic, readonly) NSArray<FLEXProperty *> *classProperties;
@property (nonatomic, readonly) NSArray<FLEXIvar *>     *ivars;
@property (nonatomic, readonly) NSArray<FLEXMethod *>   *methods;
@property (nonatomic, readonly) NSArray<FLEXMethod *>   *classMethods;
@property (nonatomic, readonly) NSArray<FLEXProtocol *> *protocols;

/// Super mirrors are initialized with the class that corresponds to the value passed in.
/// If you passed in an instance of a class, it's superclass is used to create this mirror.
/// If you passed in a class, then that class's superclass is used.
///
/// @note This property should be computed, not cached.
@property (nonatomic, readonly, nullable) id<FLEXMirror> superMirror NS_SWIFT_NAME(superMirror);

@end

#pragma mark FLEXMirror Class
@interface FLEXMirror : NSObject <FLEXMirror>

/// Reflects an instance of an object or \c Class.
/// @discussion \c FLEXMirror will immediately gather all useful information. Consider using the
/// \c NSObject categories provided if your code will only use a few pieces of information,
/// or if your code needs to run faster.
///
/// Regardless of whether you reflect an instance or a class object, \c methods and \c properties
/// will be populated with instance methods and properties, and \c classMethods and \c classProperties
/// will be populated with class methods and properties.
///
/// @param objectOrClass An instance of an objct or a \c Class object.
/// @throws If a metaclass object is passed in.
/// @return An instance of \c FLEXMirror.
+ (instancetype)reflect:(id)objectOrClass;

@property (nonatomic, readonly) id   value;
@property (nonatomic, readonly) BOOL isClass;
@property (nonatomic, readonly) NSString *className;

@property (nonatomic, readonly) NSArray<FLEXProperty *> *properties;
@property (nonatomic, readonly) NSArray<FLEXProperty *> *classProperties;
@property (nonatomic, readonly) NSArray<FLEXIvar *>     *ivars;
@property (nonatomic, readonly) NSArray<FLEXMethod *>   *methods;
@property (nonatomic, readonly) NSArray<FLEXMethod *>   *classMethods;
@property (nonatomic, readonly) NSArray<FLEXProtocol *> *protocols;

@property (nonatomic, readonly, nullable) FLEXMirror *superMirror NS_SWIFT_NAME(superMirror);

@end


@interface FLEXMirror (ExtendedMirror)

/// @return The instance method with the given name, or \c nil if one does not exist.
- (nullable FLEXMethod *)methodNamed:(nullable NSString *)name;
/// @return The class method with the given name, or \c nil if one does not exist.
- (nullable FLEXMethod *)classMethodNamed:(nullable NSString *)name;
/// @return The instance property with the given name, or \c nil if one does not exist.
- (nullable FLEXProperty *)propertyNamed:(nullable NSString *)name;
/// @return The class property with the given name, or \c nil if one does not exist.
- (nullable FLEXProperty *)classPropertyNamed:(nullable NSString *)name;
/// @return The instance variable with the given name, or \c nil if one does not exist.
- (nullable FLEXIvar *)ivarNamed:(nullable NSString *)name;
/// @return The protocol with the given name, or \c nil if one does not exist.
- (nullable FLEXProtocol *)protocolNamed:(nullable NSString *)name;

@end

NS_ASSUME_NONNULL_END
