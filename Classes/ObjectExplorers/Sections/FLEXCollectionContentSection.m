//
//  FLEXCollectionContentSection.m
//  FLEX
//
//  Created by Tanner Bennett on 8/28/19.
//  Copyright © 2019 Flipboard. All rights reserved.
//

#import "FLEXCollectionContentSection.h"
#import "FLEXUtility.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXSubtitleTableViewCell.h"
#import "FLEXTableView.h"
#import "FLEXObjectExplorerFactory.h"

typedef NS_ENUM(NSUInteger, FLEXCollectionType) {
    FLEXUnsupportedCollection,
    FLEXOrderedCollection,
    FLEXUnorderedCollection,
    FLEXKeyedCollection
};

@interface FLEXCollectionContentSection ()
@property (nonatomic, copy) id<FLEXCollection> cachedCollection;
@property (nonatomic, readonly) id<FLEXCollection> collection;
@property (nonatomic, readonly) FLEXCollectionContentFuture collectionFuture;
@property (nonatomic, readonly) FLEXCollectionType collectionType;
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
    return section;
}

+ (id)forReusableFuture:(FLEXCollectionContentFuture)collectionFuture {
    FLEXCollectionContentSection *section = [self new];
    section->_collectionFuture = collectionFuture;
    section.cachedCollection = collectionFuture(section);
    section->_collectionType = [self typeForCollection:section.cachedCollection];
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
        
        id<FLEXMutableCollection> tmp = self.collection.mutableCopy;
        [tmp filterUsingPredicate:filter];
        self.cachedCollection = tmp;
    } else {
        self.cachedCollection = self.collection ?: self.collectionFuture(self);
    }
}

- (void)reloadData {
    if (self.collectionFuture) {
        self.cachedCollection = self.collectionFuture(self);
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
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
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
