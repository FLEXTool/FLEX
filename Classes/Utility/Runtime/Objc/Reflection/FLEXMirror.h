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
- (instancetype)initWithSubject:(id)objectOrClass NS_SWIFT_NAME(init(reflecting:));

/// The underlying object or \c Class used to create this \c FLEXMirror instance.
@property (nonatomic, readonly) id   value;
/// Whether the reflected thing was a class or a class instance.
@property (nonatomic, readonly) BOOL isClass;
/// The name of the \c Class of the \c value property.
@property (nonatomic, readonly) NSString *className;

@property (nonatomic, readonly) NSArray<FLEXProperty *> *properties;
@property (nonatomic, readonly) NSArray<FLEXIvar *>     *ivars;
@property (nonatomic, readonly) NSArray<FLEXMethod *>   *methods;
@property (nonatomic, readonly) NSArray<FLEXProtocol *> *protocols;

/// @return A reflection of \c value.superClass.
@property (nonatomic, readonly, nullable) id<FLEXMirror> superMirror NS_SWIFT_NAME(superMirror);

@end

#pragma mark FLEXMirror Class
@interface FLEXMirror : NSObject <FLEXMirror>

/// Reflects an instance of an object or \c Class.
/// @discussion \c FLEXMirror will immediately gather all useful information. Consider using the
/// \c NSObject categories provided if your code will only use a few pieces of information,
/// or if your code needs to run faster.
///
/// If you reflect an instance of a class then \c methods and \c properties will be populated
/// with instance methods and properties. If you reflect a class itself, then \c methods
/// and \c properties will be populated with class methods and properties as you'd expect.
///
/// @param objectOrClass An instance of an objct or a \c Class object.
/// @return An instance of \c FLEXMirror.
+ (instancetype)reflect:(id)objectOrClass;

@property (nonatomic, readonly) id   value;
@property (nonatomic, readonly) BOOL isClass;
@property (nonatomic, readonly) NSString *className;

@property (nonatomic, readonly) NSArray<FLEXProperty *> *properties;
@property (nonatomic, readonly) NSArray<FLEXIvar *>     *ivars;
@property (nonatomic, readonly) NSArray<FLEXMethod *>   *methods;
@property (nonatomic, readonly) NSArray<FLEXProtocol *> *protocols;

@property (nonatomic, readonly, nullable) FLEXMirror *superMirror NS_SWIFT_NAME(superMirror);

@end


@interface FLEXMirror (ExtendedMirror)

/// @return The method with the given name, or \c nil if one does not exist.
- (nullable FLEXMethod *)methodNamed:(nullable NSString *)name;
/// @return The property with the given name, or \c nil if one does not exist.
- (nullable FLEXProperty *)propertyNamed:(nullable NSString *)name;
/// @return The instance variable with the given name, or \c nil if one does not exist.
- (nullable FLEXIvar *)ivarNamed:(nullable NSString *)name;
/// @return The protocol with the given name, or \c nil if one does not exist.
- (nullable FLEXProtocol *)protocolNamed:(nullable NSString *)name;

@end

NS_ASSUME_NONNULL_END
