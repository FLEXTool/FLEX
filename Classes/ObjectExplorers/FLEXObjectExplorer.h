//
//  FLEXObjectExplorer.h
//  FLEX
//
//  Created by Tanner Bennett on 8/28/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import "FLEXRuntime+UIKitHelpers.h"

@interface FLEXObjectExplorer : NSObject

+ (instancetype)forObject:(id)objectOrClass;

@property (nonatomic, readonly) id object;
/// Subclasses can override to provide a more useful description
@property (nonatomic, readonly) NSAttributedString *objectDescription;

/// @return \c YES if \c object is an instance of a class,
/// or \c NO if \c object is a class itself.
@property (nonatomic, readonly) BOOL objectIsInstance;

/// An index into the `classHierarchy` array.
///
/// This property determines which set of data comes out of the metadata arrays below
/// For example, \c properties contains the properties of the selected class scope,
/// while \c allProperties is an array of arrays where each array is a set of
/// properties for a class in the class hierarchy of the current object.
@property (nonatomic) NSInteger classScope;

@property (nonatomic, readonly) NSArray<NSArray<FLEXProperty *> *> *allProperties;
@property (nonatomic, readonly) NSArray<FLEXProperty *> *properties;

@property (nonatomic, readonly) NSArray<NSArray<FLEXProperty *> *> *allClassProperties;
@property (nonatomic, readonly) NSArray<FLEXProperty *> *classProperties;

@property (nonatomic, readonly) NSArray<NSArray<FLEXIvar *> *> *allIvars;
@property (nonatomic, readonly) NSArray<FLEXIvar *> *ivars;

@property (nonatomic, readonly) NSArray<NSArray<FLEXMethod *> *> *allMethods;
@property (nonatomic, readonly) NSArray<FLEXMethod *> *methods;

@property (nonatomic, readonly) NSArray<NSArray<FLEXMethod *> *> *allClassMethods;
@property (nonatomic, readonly) NSArray<FLEXMethod *> *classMethods;

@property (nonatomic, readonly) NSArray<Class> *classHierarchyClasses;
@property (nonatomic, readonly) NSArray<FLEXStaticMetadata *> *classHierarchy;

@property (nonatomic, readonly) NSArray<NSArray<FLEXProtocol *> *> *allConformedProtocols;
@property (nonatomic, readonly) NSArray<FLEXProtocol *> *conformedProtocols;

@property (nonatomic, readonly) NSArray<FLEXStaticMetadata *> *allInstanceSizes;
@property (nonatomic, readonly) FLEXStaticMetadata *instanceSize;

@property (nonatomic, readonly) NSArray<FLEXStaticMetadata *> *allImageNames;
@property (nonatomic, readonly) FLEXStaticMetadata *imageName;

- (void)reloadMetadata;
- (void)reloadClassHierarchy;

@end
