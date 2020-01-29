//
//  FLEXCollectionContentSection.h
//  FLEX
//
//  Created by Tanner Bennett on 8/28/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import "FLEXTableViewSection.h"
#import "FLEXObjectInfoSection.h"
@class FLEXCollectionContentSection;
@protocol FLEXCollection;

typedef id<FLEXCollection>(^FLEXCollectionContentFuture)(__kindof FLEXCollectionContentSection *section);

#pragma mark Collection
/// A protocol that enables \c FLEXCollectionContentSection to operate on any arbitrary collection.
/// \c NSArray, \c NSDictionary, \c NSSet, and \c NSOrderedSet all conform to this protocol.
@protocol FLEXCollection <NSObject, NSFastEnumeration>

@property (nonatomic, readonly) NSUInteger count;

- (id)copy;
- (id)mutableCopy;

@optional

/// Unordered, unkeyed collections must implement this
@property (nonatomic, readonly) NSArray *allObjects;
/// Keyed collections must implement this and \c objectForKeyedSubscript:
@property (nonatomic, readonly) NSArray *allKeys;

/// Ordered, indexed collections must implement this.
- (id)objectAtIndexedSubscript:(NSUInteger)idx;
/// Keyed, unordered collections must implement this and \c allKeys
- (id)objectForKeyedSubscript:(id)idx;

@end

@interface NSArray (FLEXCollection) <FLEXCollection> @end
@interface NSDictionary (FLEXCollection) <FLEXCollection> @end
@interface NSSet (FLEXCollection) <FLEXCollection> @end
@interface NSOrderedSet (FLEXCollection) <FLEXCollection> @end

#pragma mark - FLEXCollectionContentSection
/// A custom section for viewing collection elements.
///
/// Tapping on a row pushes an object explorer for that element.
@interface FLEXCollectionContentSection : FLEXTableViewSection <FLEXObjectInfoSection>

+ (instancetype)forCollection:(id<FLEXCollection>)collection;
/// The future given should be safe to call more than once.
/// The result of calling this future multiple times may yield
/// different results each time if the data is changing by nature.
+ (instancetype)forReusableFuture:(FLEXCollectionContentFuture)collectionFuture;

@end
