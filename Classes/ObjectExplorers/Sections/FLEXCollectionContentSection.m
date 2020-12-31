//
//  FLEXCollectionContentSection.m
//  FLEX
//
//  Created by Tanner Bennett on 8/28/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXCollectionContentSection.h"
#import "FLEXUtility.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXSubtitleTableViewCell.h"
#import "FLEXTableView.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXDefaultEditorViewController.h"

typedef NS_ENUM(NSUInteger, FLEXCollectionType) {
    FLEXUnsupportedCollection,
    FLEXOrderedCollection,
    FLEXUnorderedCollection,
    FLEXKeyedCollection
};

@interface NSArray (FLEXCollection) <FLEXCollection> @end
@interface NSSet (FLEXCollection) <FLEXCollection> @end
@interface NSOrderedSet (FLEXCollection) <FLEXCollection> @end
@interface NSDictionary (FLEXCollection) <FLEXCollection> @end

@interface NSMutableArray (FLEXMutableCollection) <FLEXMutableCollection> @end
@interface NSMutableSet (FLEXMutableCollection) <FLEXMutableCollection> @end
@interface NSMutableOrderedSet (FLEXMutableCollection) <FLEXMutableCollection> @end
@interface NSMutableDictionary (FLEXMutableCollection) <FLEXMutableCollection>
- (void)filterUsingPredicate:(NSPredicate *)predicate;
@end

@interface FLEXCollectionContentSection ()
/// Generated from \c collectionFuture or \c collection
@property (nonatomic, copy) id<FLEXCollection> cachedCollection;
/// A static collection to display
@property (nonatomic, readonly) id<FLEXCollection> collection;
/// A collection that may change over time and can be called upon for new data
@property (nonatomic, readonly) FLEXCollectionContentFuture collectionFuture;
@property (nonatomic, readonly) FLEXCollectionType collectionType;
@property (nonatomic, readonly) BOOL isMutable;
@end

@implementation FLEXCollectionContentSection
@synthesize filterText = _filterText;

#pragma mark Initialization

+ (instancetype)forObject:(id)object {
    return [self forCollection:object];
}

+ (id)forCollection:(id<FLEXCollection>)collection {
    FLEXCollectionContentSection *section = [self new];
    section->_collectionType = [self typeForCollection:collection];
    section->_collection = collection;
    section.cachedCollection = collection;
    section->_isMutable = [collection respondsToSelector:@selector(filterUsingPredicate:)];
    return section;
}

+ (id)forReusableFuture:(FLEXCollectionContentFuture)collectionFuture {
    FLEXCollectionContentSection *section = [self new];
    section->_collectionFuture = collectionFuture;
    section.cachedCollection = (id<FLEXCollection>)collectionFuture(section);
    section->_collectionType = [self typeForCollection:section.cachedCollection];
    section->_isMutable = [section->_cachedCollection respondsToSelector:@selector(filterUsingPredicate:)];
    return section;
}


#pragma mark - Misc

+ (FLEXCollectionType)typeForCollection:(id<FLEXCollection>)collection {
    // Order matters here, as NSDictionary is keyed but it responds to allObjects
    if ([collection respondsToSelector:@selector(objectAtIndex:)]) {
        return FLEXOrderedCollection;
    }
    if ([collection respondsToSelector:@selector(objectForKey:)]) {
        return FLEXKeyedCollection;
    }
    if ([collection respondsToSelector:@selector(allObjects)]) {
        return FLEXUnorderedCollection;
    }

    [NSException raise:NSInvalidArgumentException
                format:@"Given collection does not properly conform to FLEXCollection"];
    return FLEXUnsupportedCollection;
}

/// Row titles
/// - Ordered: the index
/// - Unordered: the object
/// - Keyed: the key
- (NSString *)titleForRow:(NSInteger)row {
    switch (self.collectionType) {
        case FLEXOrderedCollection:
            if (!self.hideOrderIndexes) {
                return @(row).stringValue;
            }
            // Fall-through
        case FLEXUnorderedCollection:
            return [self describe:[self objectForRow:row]];
        case FLEXKeyedCollection:
            return [self describe:self.cachedCollection.allKeys[row]];

        case FLEXUnsupportedCollection:
            return nil;
    }
}

/// Row subtitles
/// - Ordered: the object
/// - Unordered: nothing
/// - Keyed: the value
- (NSString *)subtitleForRow:(NSInteger)row {
    switch (self.collectionType) {
        case FLEXOrderedCollection:
            if (!self.hideOrderIndexes) {
                nil;
            }
            // Fall-through
        case FLEXKeyedCollection:
            return [self describe:[self objectForRow:row]];
        case FLEXUnorderedCollection:
            return nil;

        case FLEXUnsupportedCollection:
            return nil;
    }
}

- (NSString *)describe:(id)object {
    return [FLEXRuntimeUtility summaryForObject:object];
}

- (id)objectForRow:(NSInteger)row {
    switch (self.collectionType) {
        case FLEXOrderedCollection:
            return self.cachedCollection[row];
        case FLEXUnorderedCollection:
            return self.cachedCollection.allObjects[row];
        case FLEXKeyedCollection:
            return self.cachedCollection[self.cachedCollection.allKeys[row]];

        case FLEXUnsupportedCollection:
            return nil;
    }
}

- (UITableViewCellAccessoryType)accessoryTypeForRow:(NSInteger)row {
    return UITableViewCellAccessoryDisclosureIndicator;
//    return self.isMutable ? UITableViewCellAccessoryDetailDisclosureButton : UITableViewCellAccessoryDisclosureIndicator;
}


#pragma mark - Overrides

- (NSString *)title {
    if (!self.hideSectionTitle) {
        if (self.customTitle) {
            return self.customTitle;
        }
        
        return FLEXPluralString(self.cachedCollection.count, @"Entries", @"Entry");
    }
    
    return nil;
}

- (NSInteger)numberOfRows {
    return self.cachedCollection.count;
}

- (void)setFilterText:(NSString *)filterText {
    super.filterText = filterText;
    
    if (filterText.length) {
        BOOL (^matcher)(id, id) = self.customFilter ?: ^BOOL(NSString *query, id obj) {
            return [[self describe:obj] localizedCaseInsensitiveContainsString:query];
        };
        
        NSPredicate *filter = [NSPredicate predicateWithBlock:^BOOL(id obj, NSDictionary *bindings) {
            return matcher(filterText, obj);
        }];
        
        id<FLEXMutableCollection> tmp = self.cachedCollection.mutableCopy;
        [tmp filterUsingPredicate:filter];
        self.cachedCollection = tmp;
    } else {
        self.cachedCollection = self.collection ?: (id<FLEXCollection>)self.collectionFuture(self);
    }
}

- (void)reloadData {
    if (self.collectionFuture) {
        self.cachedCollection = (id<FLEXCollection>)self.collectionFuture(self);
    } else {
        self.cachedCollection = self.collection.copy;
    }
}

- (BOOL)canSelectRow:(NSInteger)row {
    return YES;
}

- (UIViewController *)viewControllerToPushForRow:(NSInteger)row {
    return [FLEXObjectExplorerFactory explorerViewControllerForObject:[self objectForRow:row]];
}

- (NSString *)reuseIdentifierForRow:(NSInteger)row {
    return kFLEXDetailCell;
}

- (void)configureCell:(__kindof FLEXTableViewCell *)cell forRow:(NSInteger)row {
    cell.titleLabel.text = [self titleForRow:row];
    cell.subtitleLabel.text = [self subtitleForRow:row];
    cell.accessoryType = [self accessoryTypeForRow:row];
}

@end


#pragma mark - NSMutableDictionary

@implementation NSMutableDictionary (FLEXMutableCollection)

- (void)filterUsingPredicate:(NSPredicate *)predicate {
    id test = ^BOOL(id key, NSUInteger idx, BOOL *stop) {
        if ([predicate evaluateWithObject:key]) {
            return NO;
        }
        
        return ![predicate evaluateWithObject:self[key]];
    };
    
    NSArray *keys = self.allKeys;
    NSIndexSet *remove = [keys indexesOfObjectsPassingTest:test];
    
    [self removeObjectsForKeys:[keys objectsAtIndexes:remove]];
}

@end
